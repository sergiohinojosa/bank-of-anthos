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

import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


public final class TransactionMemoryLeak {
    private static final Logger LOGGER =
        LogManager.getLogger(LedgerWriterController.class);

    private static TransactionMemoryLeak instance;
    private Map<String, Transaction> myLeak = Map.of();

    private TransactionMemoryLeak() { }

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
        //instance
        LOGGER.info("About to grow size: " + instance.myLeak.size());
        instance.myLeak.put(transaction.getRequestUuid(), transaction);
        LOGGER.info("Increasing Memory Leak, size: " + myLeak.size());
}
}
