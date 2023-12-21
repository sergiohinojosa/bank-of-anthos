# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Userservice manages user account creation, user login, and related tasks
"""

import atexit
from datetime import datetime, timedelta
import logging
import json
import os
import sys
import re

import bcrypt
import jwt
from flask import Flask, jsonify, request
import bleach
from sqlalchemy.exc import OperationalError, SQLAlchemyError

from opentelemetry import trace
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.propagate import set_global_textmap
from opentelemetry.sdk.resources import SERVICE_NAME, Resource

# Import exporters
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

# Trace imports
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.jinja2 import Jinja2Instrumentor


from db import UserDb

def create_app():
    """Flask application factory to create instances
    of the Userservice Flask App
    """
    app = Flask(__name__)

    # Disabling unused-variable for lines with route decorated functions
    # as pylint thinks they are unused
    # pylint: disable=unused-variable

    @app.route('/version', methods=['GET'])
    def version():
        """
        Service version endpoint
        """
        return app.config['VERSION'], 200

    @app.route('/ready', methods=['GET'])
    def readiness():
        """
        Readiness probe
        """
        return 'ok', 200

    @app.route('/users', methods=['POST'])
    def create_user():
        """Create a user record.

        Fails if that username already exists.

        Generates a unique accountid.

        request fields:
        - username
        - password
        - password-repeat
        - firstname
        - lastname
        - birthday
        - timezone
        - address
        - state
        - zip
        - ssn
        """
        try:
            app.logger.debug('Sanitizing input.')
            req = {k: bleach.clean(v) for k, v in request.form.items()}
            __validate_new_user(req)
            # Check if user already exists
            if users_db.get_user(req['username']) is not None:
                raise NameError('user {} already exists'.format(req['username']))

            # Create password hash with salt
            app.logger.debug("Creating password hash.")
            password = req['password']
            salt = bcrypt.gensalt()
            passhash = bcrypt.hashpw(password.encode('utf-8'), salt)

            accountid = users_db.generate_accountid()

            # Create user data to be added to the database
            user_data = {
                'accountid': accountid,
                'username': req['username'],
                'passhash': passhash,
                'firstname': req['firstname'],
                'lastname': req['lastname'],
                'birthday': req['birthday'],
                'timezone': req['timezone'],
                'address': req['address'],
                'state': req['state'],
                'zip': req['zip'],
                'ssn': req['ssn'],
            }
            # Add user_data to database
            app.logger.debug("Adding user to the database")
            users_db.add_user(user_data)
            app.logger.info("Successfully created user.")

        except UserWarning as warn:
            app.logger.error("Error creating new user: %s", str(warn))
            return str(warn), 400
        except NameError as err:
            app.logger.error("Error creating new user: %s", str(err))
            return str(err), 409
        except SQLAlchemyError as err:
            app.logger.error("Error creating new user: %s", str(err))
            return 'failed to create user', 500

        return jsonify({}), 201

    def __validate_new_user(req):
        app.logger.debug('validating create user request: %s', str(req))
        # Check if required fields are filled
        fields = (
            'username',
            'password',
            'password-repeat',
            'firstname',
            'lastname',
            'birthday',
            'timezone',
            'address',
            'state',
            'zip',
            'ssn',
        )
        if any(f not in req for f in fields):
            raise UserWarning('missing required field(s)')
        if any(not bool(req[f] or req[f].strip()) for f in fields):
            raise UserWarning('missing value for input field(s)')

        # Verify username contains only 2-15 alphanumeric or underscore characters
        if not re.match(r"\A[a-zA-Z0-9_]{2,15}\Z", req['username']):
            raise UserWarning('username must contain 2-15 alphanumeric characters or underscores')
        # Check if passwords match
        if not req['password'] == req['password-repeat']:
            raise UserWarning('passwords do not match')

    @app.route('/login', methods=['GET'])
    def login():
        """Login a user and return a JWT token

        Fails if username doesn't exist or password doesn't match hash

        token expiry time determined by environment variable

        request fields:
        - username
        - password
        """
        app.logger.debug('Sanitizing login input.')
        username = bleach.clean(request.args.get('username'))
        password = bleach.clean(request.args.get('password'))

        # Get user data
        try:
            app.logger.debug('Getting the user data.')
            user = users_db.get_user(username)
            if user is None:
                raise LookupError('user {} does not exist'.format(username))

            # Validate the password
            app.logger.debug('Validating the password.')
            if not bcrypt.checkpw(password.encode('utf-8'), user['passhash']):
                raise PermissionError('invalid login')

            full_name = '{} {}'.format(user['firstname'], user['lastname'])
            exp_time = datetime.utcnow() + timedelta(seconds=app.config['EXPIRY_SECONDS'])
            payload = {
                'user': username,
                'acct': user['accountid'],
                'name': full_name,
                'iat': datetime.utcnow(),
                'exp': exp_time,
            }
            app.logger.debug('Creating jwt token.')
            token = jwt.encode(payload, app.config['PRIVATE_KEY'], algorithm='RS256')
            app.logger.info('Login Successful.')
            return jsonify({'token': token}), 200

        except LookupError as err:
            app.logger.error('Error logging in: %s', str(err))
            return str(err), 404
        except PermissionError as err:
            app.logger.error('Error logging in: %s', str(err))
            return str(err), 401
        except SQLAlchemyError as err:
            app.logger.error('Error logging in: %s', str(err))
            return 'failed to retrieve user information', 500

    @atexit.register
    def _shutdown():
        """Executed when web app is terminated."""
        app.logger.info("Stopping userservice.")

    # Set up logger
    app.logger.handlers = logging.getLogger('gunicorn.error').handlers
    app.logger.setLevel(logging.getLogger('gunicorn.error').level)
    app.logger.info('Starting userservice.')

    # Retrieve DT_API_TOKEN and DT_ENDPOINT from app.config
    dt_endpoint = app.config.get('DT_ENDPOINT')
    dt_api_token = app.config.get('DT_API_TOKEN')

    # DT Endpoints
    app.config['DT_ENDPOINT'] = os.getenv('DT_ENDPOINT')
    app.config['DT_API_TOKEN'] = os.getenv('DT_API_TOKEN')

    # Set up tracing and export spans to Dynatrace.
    if os.environ['ENABLE_TRACING'] == "true":
        app.logger.info("✅ Tracing enabled.")
        app.logger.info("Sending traces to %s", dt_endpoint)

        resource = Resource(attributes={
            SERVICE_NAME: "UserService"
        })

        # Iterate over the potential data files and try reading them
        for name in ["/var/lib/dynatrace/enrichment/dt_metadata.json"]:
            try:
                data = ''
                with open(name) as f:
                    data = json.load(f if name.startswith("/var") else open(f.read()))
                    # TODO Cargarlos al resource
                    resource.update(data)
            except TypeError as e:
                # handle any other exception
                print("Error '{0}' occured. Arguments {1}.".format(e.message, e.args))

        # Use enrich_attrs here to enrich your requests to Dynatrace.
        # For example, when instrumenting with OpenTelemetry, add the data as resource attributes.
        provider = TracerProvider(resource=resource)
        processor = BatchSpanProcessor(
            OTLPSpanExporter(
                endpoint=dt_endpoint,
                headers={"Authorization": "Api-Token {}".format(dt_api_token)}
                ))

        provider.add_span_processor(processor)
        trace.set_tracer_provider(provider)
        set_global_textmap(TraceContextTextMapPropagator())
        # Add tracing auto-instrumentation for Flask, jinja and requests
        FlaskInstrumentor().instrument_app(app)
        RequestsInstrumentor().instrument()
        Jinja2Instrumentor().instrument()

    else:
        app.logger.info("🚫 Tracing disabled.")

    app.config['VERSION'] = os.environ.get('VERSION')
    app.config['EXPIRY_SECONDS'] = int(os.environ.get('TOKEN_EXPIRY_SECONDS'))
    app.config['PRIVATE_KEY'] = open(os.environ.get('PRIV_KEY_PATH'), 'r').read()
    app.config['PUBLIC_KEY'] = open(os.environ.get('PUB_KEY_PATH'), 'r').read()

    # Configure database connection
    try:
        users_db = UserDb(os.environ.get("ACCOUNTS_DB_URI"), app.logger)
    except OperationalError:
        app.logger.critical("users_db database connection failed")
        sys.exit(1)
    return app


if __name__ == "__main__":
    # Create an instance of flask server when called directly
    USERSERVICE = create_app()
    USERSERVICE.run()
