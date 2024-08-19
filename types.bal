// Index Types

type IRecordField record {|
    string name;
    string 'type;
    string category;
|};

type IRecordType record {|
    string name;
    IRecordField[] fields;
|};

type IListenerInitParam record {|
    string name;
    string 'type;
    string category;
|};

type IListener record {|
    string name;
    IListenerInitParam[] parameters;
    IRecordType[]? records;
|};

type IPackageMetaData record {|
    string organization;
    string name;
    string version;
|};

type IPackage record {|
    *IPackageMetaData;
    IListener[]? listeners;
|};

type Index record {|
    IPackage[] ballerina;
    IPackage[] ballerinax;
    string checksum = generateCheckSum();
|};

// GrpahQL Responses

type AllPackagesResponse record {|
    record {|
        record {|
            IPackageMetaData[] packages;
        |} packages;
    |} data;
|};


type ListenerResponse record {
    record {
        record {
            record {
                record {
                    string listeners;
                    string records;
                    string? unionTypes;
                }[] modules;
            } docsData;
        } apiDocs;
    } data;
};

type ElementType record {|
    string name;
    string category;
    boolean isAnonymousUnionType;
    boolean isInclusion;
    boolean isArrayType;
    boolean isNullable;
    boolean isTuple;
    boolean isIntersectionType;
    boolean isParenthesisedType;
    boolean isTypeDesc;
    boolean isRestParam;
    boolean isDeprecated;
    boolean isPublic;
    boolean generateUserDefinedTypeLink;
    anydata[] memberTypes;
    int arrayDimensions;
|};

type MemberTypesItem record {|
    boolean isAnonymousUnionType;
    boolean isInclusion;
    boolean isArrayType;
    boolean isNullable;
    boolean isTuple;
    boolean isIntersectionType;
    boolean isParenthesisedType;
    boolean isTypeDesc;
    boolean isRestParam;
    boolean isDeprecated;
    boolean isPublic;
    boolean generateUserDefinedTypeLink;
    anydata[] memberTypes;
    int arrayDimensions;
    string name?;
    string category?;
    ElementType elementType?;
|};

type Type record {|
    boolean isAnonymousUnionType;
    boolean isInclusion;
    boolean isArrayType;
    boolean isNullable;
    boolean isTuple;
    boolean isIntersectionType;
    boolean isParenthesisedType;
    boolean isTypeDesc;
    boolean isRestParam;
    boolean isDeprecated;
    boolean isPublic;
    boolean generateUserDefinedTypeLink;
    (MemberTypesItem[]|anydata[]) memberTypes;
    int arrayDimensions?;
    string name?;
    string category?;
    string orgName?;
    string moduleName?;
    string version?;
|};

type ParametersItem record {|
    string defaultValue;
    Type 'type;
    string name;
|};

type MethodsItem record {|
    (ParametersItem[]|anydata[]) parameters;
    string name;
|};

type InitMethod record {|
    ParametersItem[] parameters;
    string name;
|};

type Listener record {|
    MethodsItem[] methods;
    InitMethod initMethod;
    string name;
|};

type Parameter record {|
    string name;
    string 'type;
    string category;
|};

type ListenersItem record {|
    string name;
    Parameter[] parameters;
    anydata records;
|};

type PackageIndexItem record {|
    string orgName;
    string module;
    string version;
    ListenersItem[] listeners;
|};

// Records Response

type FieldsItem record {|
    string defaultValue?;
    Type 'type?;
    string name?;
|};

type Record record {|
    FieldsItem[] fields;
    string name;
|};

