/*
 * Copyright 2020, Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package anthos.samples.bankofanthos.ledgerwriter;

import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public final class TransactionMemoryLeak {
    private static final Logger LOGGER = LogManager.getLogger(TransactionMemoryLeak.class);

    private static TransactionMemoryLeak instance;
    private List<String> myLeak = new ArrayList<String>();

    private TransactionMemoryLeak() {
    }

    // static block initialization for exception handling
    static {
        try {
            instance = new TransactionMemoryLeak();
        } catch (Exception e) {
            throw new RuntimeException("Exception occurred in creating singleton instance");
        }
    }

    public static TransactionMemoryLeak getInstance() {
        return instance;
    }

    public void grow(Transaction transaction) {
        // instance
        int size = instance.myLeak.size();
        LOGGER.warn("About to grow size: " + size);

        StringBuilder belly = new StringBuilder();
        belly.append(size + "-[");

        // We add in the next entry all previous tx and multiply it by the amount of the
        // array
        for (String tx : myLeak) {
            StringBuilder factor = new StringBuilder();
            factor.append("(");
            factor.append(String.valueOf(size));
            factor.append(")_");
            factor.append(tx);
            belly.append(factor.toString());
            belly.append("_2_" + factor.toString());
        }

        belly.append("ID:");
        belly.append(transaction.getTransactionId());
        belly.append("|$_");
        belly.append(transaction.getAmount());
        belly.append("|From_");
        belly.append(transaction.getFromAccountNum());
        belly.append("|To_");
        belly.append(transaction.getToAccountNum());
        belly.append("|Uuid_");
        belly.append(transaction.getRequestUuid());
        belly.append("|RoutingNum_");
        belly.append(transaction.getToRoutingNum());
        belly.append("]");
        instance.myLeak.add(belly.toString());

        LOGGER.warn("Increasing Memory Leak, size: " + myLeak.size());
    }
}
