/*
 *  Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package org.wso2.apk.enforcer.commons.analytics.collectors.impl;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.wso2.apk.enforcer.commons.analytics.collectors.AnalyticsDataProvider;
import org.wso2.apk.enforcer.commons.analytics.collectors.RequestDataCollector;

/**
 * Unclassified request data collector.
 */
public class UnclassifiedRequestDataCollector extends CommonRequestDataCollector implements RequestDataCollector {
    private static final Log log = LogFactory.getLog(UnclassifiedRequestDataCollector.class);

    public UnclassifiedRequestDataCollector(AnalyticsDataProvider provider) {
        super(provider);
    }

    public void collectData() {
        log.debug("Skipping Unclassified analytics types");
    }

}
