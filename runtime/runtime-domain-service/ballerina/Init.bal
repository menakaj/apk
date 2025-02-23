//
// Copyright (c) 2022, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//
import ballerina/log;
import ballerina/http;
import ballerina/uuid;
import wso2/apk_common_lib as commons;

configurable RuntimeConfiguratation & readonly runtimeConfiguration = {
    keyStores: {
        signing: {
            keyFilePath: "/home/wso2apk/runtime/security/wso2carbon.key"
        },
        tls: {
            keyFilePath: "/home/wso2apk/runtime/security/wso2carbon.key"
        }
    },
    idpConfiguration: {publicKey: {certFilePath: "/home/wso2apk/runtime/security/mg.pem"}},
    controlPlane: {serviceBaseURl: ""}
};

isolated function initializeServiceBaseResolver() returns ServiceBaseOrgResolver|error {
    map<string> headers = {};
    foreach Header & readonly header in runtimeConfiguration.controlPlane.headers {
        headers[header.name] = header.value;
    }
    return check new (runtimeConfiguration.controlPlane.serviceBaseURl, headers, runtimeConfiguration.controlPlane.certificate, runtimeConfiguration.controlPlane.enableAuthentication);
}

final K8sBaseOrgResolver k8sBaseOrgResolver = new;
final ServiceBaseOrgResolver serviceBaseOrgResolver = check initializeServiceBaseResolver();
final commons:JWTBaseOrgResolver jwtBaseOrgResolver = new;

isolated function getOrgResolver() returns commons:OrganizationResolver {
    if runtimeConfiguration.orgResolver == ORG_RESOLVER_CONTROL_PLANE {
        return serviceBaseOrgResolver;
    } else if runtimeConfiguration.orgResolver == ORG_RESOLVER_K8s {
        return k8sBaseOrgResolver;
    } else {
        return jwtBaseOrgResolver;
    }
}

commons:JWTValidationInterceptor jwtValidationInterceptor = new (runtimeConfiguration.idpConfiguration, getOrgResolver());
commons:RequestErrorInterceptor requestErrorInterceptor = new;
commons:ResponseErrorInterceptor responseErrorInterceptor = new;
listener http:Listener ep1 = new (9444, secureSocket = {
    'key: {
        certFile: <string>runtimeConfiguration.keyStores.tls.certFilePath,
        keyFile: <string>runtimeConfiguration.keyStores.tls.keyFilePath
    }
},
    interceptors = [requestErrorInterceptor, responseErrorInterceptor]
    );
listener http:Listener ep0 = new (9443,
secureSocket = {
    'key: {
        certFile: <string>runtimeConfiguration.keyStores.tls.certFilePath,
        keyFile: <string>runtimeConfiguration.keyStores.tls.keyFilePath
    }
},
    interceptors = [jwtValidationInterceptor, requestErrorInterceptor, responseErrorInterceptor]
    );
string kid = uuid:createType1AsString();

# Initializing method for runtime
# + return - Return Error if error occured at initialization.
function init() returns error? {
    APIClient apiService = new ();
    error? retrieveAllApisAtStartup = apiService.retrieveAllApisAtStartup((), ());
    if retrieveAllApisAtStartup is error {
        log:printError("Error occured while retrieving API List", retrieveAllApisAtStartup);
    }

    ServiceClient servicesService = new ();
    error? retrieveAllServicesAtStartup = servicesService.retrieveAllServicesAtStartup((), ());
    if retrieveAllServicesAtStartup is error {
        log:printError("Error occured while retrieving Service List", retrieveAllServicesAtStartup);
    }
    OrgClient orgClient = new ();
    error? retrieveAllOrganizationsAtStartup = orgClient.retrieveAllOrganizationsAtStartup((), ());
    if retrieveAllOrganizationsAtStartup is error {
        log:printError("Error occured while retrieving Organization List", retrieveAllOrganizationsAtStartup);
    }
    APIListingTask apiListingTask = new (apiResourceVersion);
    _ = check apiListingTask.startListening();
    ServiceTask serviceTask = new (servicesResourceVersion);
    _ = check serviceTask.startListening();
    _ = check servicesService.retrieveAllServiceMappingsAtStartup((), ());
    ServiceMappingTask serviceMappingTask = new (serviceMappingResourceVersion);
    _ = check serviceMappingTask.startListening();
    OrganizationListingTask organizationListingTask = new (organizationResourceVersion);
    _ = check organizationListingTask.startListening();
    _ = check retrieveAllConfigMapsAtStartup((), ());
    ConfigMapListingTask configMapTask = new (configMapResourceVersion);
    _ = check configMapTask.startListening();
    log:printInfo("Initializing Runtime Domain Service..");
}
