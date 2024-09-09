import ballerina/data.jsondata;
import ballerina/graphql;
import ballerina/io;
import ballerina/lang.runtime;

configurable string centralEP = "https://api.central.ballerina.io/2.0/graphql";
configurable string ballerinaVersion = "2201.10.0";

final graphql:Client graphqlClient = check new (centralEP);

public function main() returns error? {

    IPackageMetaData[] ballerina = (check getAllPackages("ballerina")).data.packages.packages;

    IPackageMetaData[] ballerinax = (check getAllPackages("ballerinax")).data.packages.packages;

    IPackage[] bPkgs = [];
    int count = 1;
    foreach IPackageMetaData bPkg in ballerina {
        if bPkg.name.startsWith("lang.") {
            continue;
        }
        if count % 40 == 0 {
            runtime:sleep(61);
        }
        count += 1;
        IPackage? iPackage = check getIPackage(bPkg);
        if iPackage != () {
            bPkgs.push(iPackage);
        }
    }

    IPackage[] bxPkgs = [];
    count = 1;
    foreach IPackageMetaData bxPkg in ballerinax {
        if bxPkg.name.startsWith("health.fhir.templates.r4") {
            continue;
        }
        if count % 40 == 0 {
            runtime:sleep(61);
        }
        count += 1;
        IPackage? iPackage = check getIPackage(bxPkg);
        if iPackage != () {
            bxPkgs.push(iPackage);
        }
    }

    Index index = {
        ballerina: bPkgs,
        ballerinax: bxPkgs
    };

    check io:fileWriteJson(string `LS-INDEX-${ballerinaVersion}.json`, index.toJson());
}

function getIPackage(IPackageMetaData packageMetaData) returns IPackage|error? {
    io:println(packageMetaData.name);

    ListenerResponse response = check getListenerReponse(packageMetaData.organization, packageMetaData.name, packageMetaData.version);

    string listenersStr = response.data.apiDocs.docsData.modules[0].listeners;
    if listenersStr == "[]" || listenersStr == "" {
        return ();
    }

    json js = check jsondata:parseString(listenersStr);
    Listener[] listeners = check jsondata:parseAsType(js);

    json j = check jsondata:parseString(response.data.apiDocs.docsData.modules[0].records);
    Record[] records = check jsondata:parseAsType(j);

    IPackage iPackage = {
        ...packageMetaData,
        listeners: buildPackageIndex(listeners, records)
    };
    return iPackage;
}

function getListenerReponse(string orgName, string moduleName, string version) returns ListenerResponse|error {
    string document = string `query ApiDocs {
        apiDocs(
            inputFilter: {
                moduleInfo: { moduleName: "${moduleName}", orgName: "${orgName}", version: "${version}" }
            }
        ) {
            docsData {
                modules {
                    listeners
                    records
                    unionTypes
                }
            }
        }
    }`;

    return graphqlClient->execute(document);
}

function getAllPackages(string orgName) returns AllPackagesResponse|error {
    string document = string `query Packages {
        packages(orgName: "${orgName}", limit: 1000) {
            packages {
                name
                version
                organization
            }
        }
    }`;

    return graphqlClient->execute(document);
}

function buildPackageIndex(Listener[] listeners, Record[] records) returns IListener[] => from var l in listeners
    select getListenerInitParams(l, records);

function getListenerInitParams(Listener l, Record[] rs) returns IListener {
    IListenerInitParam[] initParams = [];
    string[] requiredRecords = [];
    string[] inclusionRecords = [];
    foreach var {name, defaultValue, 'type} in l.initMethod.parameters {
        string? category = 'type.category;
        if category == "builtin" && defaultValue == "" {
            initParams.push({name, category, 'type: <string>'type.name});
        } else if category == "records" && defaultValue == "" {
            if 'type.isInclusion {
                inclusionRecords.push(<string>'type.name);
            } else {
                initParams.push({name, category, 'type: <string>'type.name});
                requiredRecords.push(<string>'type.name);
            }
        } else if defaultValue == "" && 'type.isAnonymousUnionType {
            MemberTypesItem|anydata unionResult = 'type.memberTypes[0];
            if unionResult is MemberTypesItem {
                initParams.push({name, category: <string>unionResult.category, 'type: <string>unionResult.name});
            }
        }
    }

    IRecordType[] records = [];
    foreach var r in rs {
        if requiredRecords.indexOf(<string>r.name) != () {
            records.push(buildRecordsRequiredForInit(r));
        } else if inclusionRecords.indexOf(<string>r.name) != () {
            IRecordField[] fields = filterDefaultValueFields(r.fields);
            initParams.push(...fields);
        }
    }

    return {
        records: records.length() > 0 ? records : (),
        name: l.name,
        parameters: initParams
    };
}

function buildRecordsRequiredForInit(Record r) returns IRecordType => {
    name: <string>r.name,
    fields: filterDefaultValueFields(r.fields)
};

function filterDefaultValueFields(FieldsItem[] fields) returns IRecordField[] {
    return from var {name, defaultValue, 'type} in fields
        where 'type != ()
        where 'type.category == "builtin" && defaultValue == "" && !'type.isNullable
        select {name: <string>name, 'type: <string>'type.name, category: <string>'type.category};
}
