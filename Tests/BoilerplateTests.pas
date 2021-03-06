unit BoilerplateTests;

interface

uses
  SynTests;

type
  TBoilerplateHTTPServerShould = class(TSynTestCase)
    procedure CallInherited;
    procedure ServeExactCaseURL;
    procedure LoadAndReturnAssets;
    procedure SpecifyCrossOrigin;
    procedure SpecifyCrossOriginForImages;
    procedure SpecifyCrossOriginForFonts;
    procedure SpecifyCrossOriginTiming;
    procedure DelegateBadRequestTo404;
    procedure DelegateUnauthorizedTo404;
    procedure DelegateForbiddenTo404;
    procedure DelegateNotFoundTo404;
    procedure DelegateNotAllowedTo404;
    procedure DelegateNotAcceptableTo404;
    procedure SetXUACompatible;
    procedure ForceMIMEType;
    procedure ForceTextUTF8Charset;
    procedure ForceUTF8Charset;
    procedure ForceHTTPS;
    procedure ForceHTTPSExceptLetsEncrypt;
    procedure SupportWWWRewrite;
    procedure SetXFrameOptions;
    procedure SupportContentSecurityPolicy;
    procedure DelegateHidden;
    procedure DelegateBlocked;
    procedure SupportStrictSSLOverHTTP;
    procedure SupportStrictSSLOverHTTPS;
    procedure PreventMIMESniffing;
    procedure EnableXSSFilter;
    procedure EnableReferrerPolicy;
    procedure DisableTRACEMethod;
    procedure DeleteXPoweredBy;
    procedure FixMangledAcceptEncoding;
    procedure ForceGZipHeader;
    procedure SetCacheNoTransform;
    procedure SetCachePublic;
    procedure EnableCacheByETag;
    procedure EnableCacheByLastModified;
    procedure SetExpires;
    procedure SetCacheMaxAge;
    procedure EnableCacheBusting;
    procedure EnableCacheBustingBeforeExt;
    procedure SupportStaticRoot;
    procedure DelegateRootToIndex;
    procedure DeleteServerInternalState;
    procedure DelegateIndexToInheritedDefault;
    procedure DelegateIndexToInheritedDefaultOverSSL;
    procedure Delegate404ToInherited_404;
    procedure RegisterCustomOptions;
    procedure UnregisterCustomOptions;
    procedure RedirectInInherited_404;
    procedure UpdateStaticAsset;
    procedure SetVaryAcceptEncoding;
    procedure SupportDNSPrefetchControl;
    procedure SupportExternalAssets;
  end;

  TCSP2Should = class(TSynTestCase)
    procedure SupportSourceList;
    procedure SupportFrameAncestors;
    procedure SupportMediaTypeList;
    procedure SupportURIReferences;
    procedure SupportSandboxTokens;
    procedure SupportDirectives;
    procedure SupportHTTPHeaders;
    procedure SupportExamples;
  end;

  TCSP3Should = class(TSynTestCase)
    procedure SupportSourceList;
    procedure SupportMediaTypeList;
    procedure SupportSandboxTokens;
    procedure SupportFrameAncestors;
    procedure SupportDirectives;
    procedure SupportExtensions;
    procedure SupportHTTPHeaders;
  end;

  TBoilerplateFeatures = class(TSynTests)
    procedure Scenarios;
  end;

implementation

uses
  {$IFDEF MSWINDOWS} Windows, {$ENDIF}
  SysUtils,
  SynCommons,
  SynCrtSock,
  SynCrypto,
  mORMot,
  mORMotMVC,
  mORMotHttpServer,
  BoilerplateAssets,
  BoilerplateHTTPServer,
  CSP;

{$IFDEF CONDITIONALEXPRESSIONS}  // Delphi 6 or newer
  {$IFNDEF VER140}
    {$WARN UNSAFE_CODE OFF} // Delphi for .Net does not exist any more!
    {$WARN UNSAFE_TYPE OFF}
    {$WARN UNSAFE_CAST OFF}
  {$ENDIF}
{$ENDIF}

// The time constants were introduced in Delphi 2009 and
// missed in Delphi 5/6/7/2005/2006/2007, and FPC
{$IF DEFINED(FPC) OR (CompilerVersion < 20)}
const
  HoursPerDay = 24;
  MinsPerHour = 60;
  SecsPerMin  = 60;
  MinsPerDay  = HoursPerDay * MinsPerHour;
  SecsPerDay  = MinsPerDay * SecsPerMin;
  SecsPerHour = SecsPerMin * MinsPerHour;
{$IFEND}

type

{ THttpServerRequestStub }

  IBoilerplateApplication = interface(IMVCApplication)
    ['{79968060-F121-46B9-BA5C-C4740B4445D6}']
    procedure _404(const Dummy: Integer; out Scope: Variant);
  end;

  THttpServerRequestStub = class(THttpServerRequest)
  private
    FResult: Cardinal;
  public
    procedure Init;
    property URL: SockString read FURL write FURL;
    property Method: SockString read FMethod write FMethod;
    property InHeaders: SockString read FInHeaders write FInHeaders;
    property InContent: SockString read FInContent;
    property InContentType: SockString read FInContentType;
    property OutContent: SockString read FOutContent;
    property OutContentType: SockString read FOutContentType;
    property OutCustomHeaders: SockString read FOutCustomHeaders
      write FOutCustomHeaders;
    property Result: Cardinal read FResult write FResult;
    property UseSSL: boolean read FUseSSL write FUseSSL;
  end;

{ TSQLRestServerURI }

  TSQLRestServerURI = class(TSQLRestServerFullMemory)
  protected
    FCustomStatus: Cardinal;
    procedure URI(var Call: TSQLRestURIParams); override;
  public
    property CustomStatus: Cardinal read FCustomStatus write FCustomStatus;
  end;

{ TBoilerplateHTTPServerSteps }

  TBoilerplateHTTPServerSteps = class(TBoilerplateHTTPServer)
  private
    FTestCase: TSynTestCase;
    FModel: TSQLModel;
    FServer: TSQLRestServer;
    FServerAccessRights: TSQLAccessRights;
    FApplication: IBoilerplateApplication;
    FContext: THttpServerRequestStub;
    FExternalAsset: TAsset;
    FExternalAssetType: THTTPAssetType;
  public
    function FullFileName(const FileName: string): string;
    procedure DeleteFile(const FileName: string);
    procedure RemoveDir(const FileName: string);
    function GetFileContent(const FileName: TFileName): RawByteString;
    function GetExternalAsset(const Path: RawUTF8;
      var AssetType: THTTPAssetType; var Asset: TAsset): Boolean;
  public
    constructor Create(const TestCase: TSynTestCase;
      const Auth: Boolean = False; AApplication: IBoilerplateApplication = nil;
      AUseSSL: Boolean = False); reintroduce;
    destructor Destroy; override;
    procedure GivenClearServer;
    procedure GivenAssets(const Name: string = 'ASSETS');
    procedure GivenExternalAsset(const AssetType: THTTPAssetType;
      const APath: RawUTF8; const ATimestamp: TUnixTime;
      const AContentType: RawUTF8; const AGZipExists, ABrotliExists: Boolean;
      const AContent, AGZipContent, ABrotliContent: RawByteString;
      const AContentHash, AGZipHash, ABrotliHash: Cardinal);
    procedure GivenOptions(const AOptions: TBoilerplateOptions);
    procedure GivenInHeader(const aName, aValue: RawUTF8);
    procedure GivenOutHeader(const aName, aValue: RawUTF8);
    procedure GivenServeExactCaseURL(const Value: Boolean = True);
    procedure GivenWWWRewrite(const Value: TWWWRewrite = wwwOff);
    procedure GivenDNSPrefetchControl(const Value: TDNSPrefetchControl);
    procedure GivenDNSPrefetchControlContentTypes(const Value: SockString);
    procedure GivenContentSecurityPolicy(const Value: SockString);
    procedure GivenContentSecurityPolicyReportOnly(const Value: SockString);
    procedure GivenStrictSSL(const Value: TStrictSSL);
    procedure GivenReferrerPolicy(const Value: RawUTF8);
    procedure GivenExpires(const Value: RawUTF8);
    procedure GivenStaticRoot(const Value: TFileName);
    procedure GivenStaticFile(const URL: SockString = '');
    procedure GivenModifiedFile(const FileName: TFileName;
      const KeepTimeStamp, KeepSize: Boolean);
    procedure GivenCustomStatus(const Status: Cardinal);
    procedure WhenRequest(const URL: SockString = '';
      const Host: SockString = ''; const UseSSL: Boolean = False;
      const Method: SockString = 'GET');
    procedure ThenRequestResultIs(const Value: Cardinal);
    procedure ThenOutHeaderValueIs(const aName, aValue: RawUTF8);
    procedure ThenOutContentIsEmpty;
    procedure ThenOutContentEqualsFile(const FileName: TFileName); overload;
    procedure ThenOutContentIsStaticFile(
      const StaticFileName, FileName: TFileName); overload;
    procedure ThenOutContentTypeIs(const Value: RawUTF8);
    procedure ThenOutContentIs(const Value: RawByteString);
    procedure ThenOutContentIsStatic(const FileName: TFileName);
    procedure ThenFileTimestampAndSizeAreEqualToAsset(const FileName: TFileName;
      const Path: RawUTF8);
    procedure ThenFileContentIsEqualToAsset(const FileName: TFileName;
      const Path: RawUTF8);
    procedure ThenFileContentIsNotEqualToAsset(const FileName: TFileName;
      const Path: RawUTF8);
    procedure ThenApp404Called;
  end;

{ TBoilerplateApplication }

  TBoilerplateApplication = class(TMVCApplication, IBoilerplateApplication)
  public
    procedure Start(Server: TSQLRestServer;
      const ViewsFolder: TFileName); reintroduce;
  published
    procedure Error(var Msg: RawUTF8; var Scope: Variant); override;
    procedure Default(var Scope: Variant);
    procedure _404(const Dummy: Integer; out Scope: Variant);
  end;

{ T404Application }

  T404Application = class(TMVCApplication, IBoilerplateApplication)
  public
    Is404Called: Boolean;
    procedure Start(Server: TSQLRestServer;
      const ViewsFolder: TFileName); reintroduce;
  published
    procedure Error(var Msg: RawUTF8; var Scope: Variant); override;
    procedure Default(var Scope: Variant);
    procedure _404(const Dummy: Integer; out Scope: Variant);
  end;

function GetMustacheParams(
  const Folder: TFileName): TMVCViewsMustacheParameters;
begin
  Result.Folder := Folder;
  Result.CSVExtensions := '';
  Result.FileTimestampMonitorAfterSeconds := 0;
  Result.ExtensionForNotExistingTemplate := '';
  Result.Helpers := nil;
end;

function NormalizeFileName(const FileName: TFileName): TFileName;
begin
  Result := FileName;
  Result := StringReplace(Result, '\', PathDelim, [rfReplaceAll]);
  Result := StringReplace(Result, '/', PathDelim, [rfReplaceAll]);
end;

{ TBoilerplateHTTPServerShould }

procedure TBoilerplateHTTPServerShould.SpecifyCrossOrigin;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    WhenRequest;
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');

    GivenClearServer;
    GivenOptions([bpoAllowCrossOrigin]);
    WhenRequest;
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');

    GivenClearServer;
    GivenOptions([bpoAllowCrossOrigin]);
    GivenInHeader('Origin', 'localhost');
    WhenRequest;
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '*');
  end;
end;

procedure TBoilerplateHTTPServerShould.SpecifyCrossOriginForFonts;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/sample.woff2');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginFonts]);
    WhenRequest('/sample.woff2');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginFonts]);
    GivenInHeader('Origin', 'localhost');
    WhenRequest('/sample.woff2');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '*');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SpecifyCrossOriginForImages;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginImages]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginImages]);
    GivenInHeader('Origin', 'localhost');
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '*');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SpecifyCrossOriginTiming;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginTiming]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Timing-Allow-Origin', '*');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportContentSecurityPolicy;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
  CSP: TCSP3;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Security-Policy',
      DEFAULT_CONTENT_SECURITY_POLICY);
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Content-Security-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenContentSecurityPolicy(
      CSP.Init.ObjectSrc.WithSelf.CSP.ScriptSrc.WithSelf.CSP.Policy);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Security-Policy',
      'object-src ''self''; script-src ''self''');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenContentSecurityPolicy(
      CSP.Init.ObjectSrc.WithSelf.CSP.ScriptSrc.WithSelf.CSP.Policy);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Content-Security-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Security-Policy-Report-Only',
      DEFAULT_CONTENT_SECURITY_POLICY_REPORT_ONLY);
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Content-Security-Policy-Report-Only', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenContentSecurityPolicyReportOnly(SockString(
      CSP.Init.ObjectSrc.WithSelf.CSP.ScriptSrc.WithSelf.CSP.Policy));
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Security-Policy-Report-Only',
      'object-src ''self''; script-src ''self''');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenContentSecurityPolicyReportOnly(
      CSP.Init.ObjectSrc.WithSelf.CSP.ScriptSrc.WithSelf.CSP.Policy);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Content-Security-Policy-Report-Only', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportDNSPrefetchControl;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    WhenRequest('/index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', 'on');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControl(dnsPrefetchNone);
    WhenRequest('/index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControl(dnsPrefetchOff);
    WhenRequest('/index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', 'off');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControl(dnsPrefetchOn);
    WhenRequest('/index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', 'on');

    GivenClearServer;
    GivenAssets;
    WhenRequest('/img/marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControl(dnsPrefetchNone);
    WhenRequest('/img/marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControl(dnsPrefetchOff);
    WhenRequest('/img/marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControl(dnsPrefetchOn);
    WhenRequest('/img/marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControlContentTypes('');
    WhenRequest('/index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControlContentTypes('');
    GivenDNSPrefetchControl(dnsPrefetchNone);
    WhenRequest('/index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControlContentTypes('');
    GivenDNSPrefetchControl(dnsPrefetchOff);
    WhenRequest('/index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControlContentTypes('');
    GivenDNSPrefetchControl(dnsPrefetchOn);
    WhenRequest('/index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControlContentTypes('image/jpeg');
    WhenRequest('/img/marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', 'on');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControlContentTypes('image/jpeg');
    GivenDNSPrefetchControl(dnsPrefetchNone);
    WhenRequest('/img/marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControlContentTypes('image/jpeg');
    GivenDNSPrefetchControl(dnsPrefetchOff);
    WhenRequest('/img/marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', 'off');

    GivenClearServer;
    GivenAssets;
    GivenDNSPrefetchControlContentTypes('image/jpeg');
    GivenDNSPrefetchControl(dnsPrefetchOn);
    WhenRequest('/img/marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('X-DNS-Prefetch-Control', 'on');
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportExternalAssets;
const
  HTTP_PERMANENT_REDIRECT = 308;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    // Non-existed external asset
    GivenClearServer;
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_NOTFOUND);

    // External asset returns identity Content, Content-Type, and Last-Modified
    GivenClearServer;
    GivenOptions([bpoEnableCacheByLastModified]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atContent, '/external-asset',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', False, False,
      'identity-content', 'gzip-content', 'brotli-content',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutContentTypeIs('test-content-type');
    ThenOutHeaderValueIs('Last-Modified', UnixTimeToHTTPDate(
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6))));
    ThenOutContentIs('identity-content');

    // External asset returns identity Content, Content-Type, and ETag
    GivenClearServer;
    GivenOptions([bpoEnableCacheByETag]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atContent, '/external-asset',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', False, False,
      'identity-content', 'gzip-content', 'brotli-content',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutContentTypeIs('test-content-type');
    ThenOutHeaderValueIs('ETag', '"12345678"');
    ThenOutContentIs('identity-content');

    // External asset returns gzip-compressed Content and ETag
    GivenClearServer;
    GivenOptions([bpoEnableCacheByETag]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atContent, '/external-asset',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', True, False,
      'identity-content', 'gzip-content', 'brotli-content',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutContentTypeIs('test-content-type');
    ThenOutHeaderValueIs('ETag', '"23456781"');
    ThenOutContentIs('gzip-content');

    // External asset returns brotli-compressed Content and ETag
    GivenClearServer;
    GivenOptions([bpoEnableCacheByETag]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atContent, '/external-asset',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', False, True,
      'identity-content', 'gzip-content', 'brotli-content',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutContentTypeIs('test-content-type');
    ThenOutHeaderValueIs('ETag', '"34567812"');
    ThenOutContentIs('brotli-content');

    // Content prefers brotli over gzip compression when both are available
    GivenClearServer;
    GivenOptions([bpoEnableCacheByETag]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atContent, '/external-asset',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', True, True,
      'identity-content', 'gzip-content', 'brotli-content',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutContentTypeIs('test-content-type');
    ThenOutHeaderValueIs('ETag', '"34567812"');
    ThenOutContentIs('brotli-content');

    // Returns gzip-compressed content if the brotli is not accepted
    GivenClearServer;
    GivenOptions([bpoEnableCacheByETag]);
    GivenInHeader('Accept-Encoding', 'gzip');
    GivenExternalAsset(atContent, '/external-asset',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', True, True,
      'identity-content', 'gzip-content', 'brotli-content',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutContentTypeIs('test-content-type');
    ThenOutHeaderValueIs('ETag', '"23456781"');
    ThenOutContentIs('gzip-content');

    // Return identity content from an external file
    GivenClearServer;
    GivenOptions([bpoEnableCacheByETag, bpoEnableCacheByLastModified]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atFile, '/external-asset',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', False, False,
      RawByteString(NormalizeFileName('Assets\index.html')),
      RawByteString(NormalizeFileName('Assets\index.html.gz')),
      RawByteString(NormalizeFileName('Assets\index.html.br')),
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('Content-Type', 'test-content-type');
    ThenOutHeaderValueIs('ETag', '"12345678"');
    ThenOutHeaderValueIs('Last-Modified', UnixTimeToHTTPDate(
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6))));
    ThenOutContentIsStatic(NormalizeFileName('Assets\index.html'));

    // Return gzip-compressed content from an external file
    GivenClearServer;
    GivenOptions([bpoEnableCacheByETag, bpoEnableCacheByLastModified]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atFile, '/external-asset',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', True, False,
      RawByteString(NormalizeFileName('Assets\index.html')),
      RawByteString(NormalizeFileName('Assets\index.html.gz')),
      RawByteString(NormalizeFileName('Assets\index.html.br')),
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('Content-Type', 'test-content-type');
    ThenOutHeaderValueIs('ETag', '"23456781"');
    ThenOutHeaderValueIs('Last-Modified', UnixTimeToHTTPDate(
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6))));
    ThenOutContentIsStatic(NormalizeFileName('Assets\index.html.gz'));

    // Return brotli-compressed content from an external file
    GivenClearServer;
    GivenOptions([bpoEnableCacheByETag, bpoEnableCacheByLastModified]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atFile, '/external-asset',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', True, True,
      RawByteString(NormalizeFileName('Assets\index.html')),
      RawByteString(NormalizeFileName('Assets\index.html.gz')),
      RawByteString(NormalizeFileName('Assets\index.html.br')),
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('Content-Type', 'test-content-type');
    ThenOutHeaderValueIs('ETag', '"34567812"');
    ThenOutHeaderValueIs('Last-Modified', UnixTimeToHTTPDate(
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6))));
    ThenOutContentIsStatic(NormalizeFileName('Assets\index.html.br'));

    // Return 301 Moved Permanently redirection to another location
    GivenClearServer;
    GivenExternalAsset(atMovedPermanentlyRedirect, '/external-asset', 0, '',
      False, False, '/another-asset', '', '', 0, 0, 0);
    WhenRequest('/external-asset', 'domain.com');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);
    ThenOutHeaderValueIs('Location', 'http://domain.com/another-asset');
    ThenOutContentIsEmpty;

    // Return 302 Found redirection to another location
    GivenClearServer;
    GivenExternalAsset(atFoundRedirect, '/external-asset', 0, '',
      False, False, '/another-asset', '', '', 0, 0, 0);
    WhenRequest('/external-asset', 'domain.com');
    ThenRequestResultIs(HTTP_FOUND);
    ThenOutHeaderValueIs('Location', 'http://domain.com/another-asset');
    ThenOutContentIsEmpty;

    // Return 303 See Other redirection to another location
    GivenClearServer;
    GivenExternalAsset(atSeeOtherRedirect, '/external-asset', 0, '',
      False, False, '/another-asset', '', '', 0, 0, 0);
    WhenRequest('/external-asset', 'domain.com');
    ThenRequestResultIs(HTTP_SEEOTHER);
    ThenOutHeaderValueIs('Location', 'http://domain.com/another-asset');
    ThenOutContentIsEmpty;

    // Return 307 Temporary Redirect redirection to another location
    GivenClearServer;
    GivenExternalAsset(atTemporaryRedirect, '/external-asset', 0, '',
      False, False, '/another-asset', '', '', 0, 0, 0);
    WhenRequest('/external-asset', 'domain.com');
    ThenRequestResultIs(HTTP_TEMPORARYREDIRECT);
    ThenOutHeaderValueIs('Location', 'http://domain.com/another-asset');
    ThenOutContentIsEmpty;

    // Return 308 Permanent Redirect redirection to another location
    GivenClearServer;
    GivenExternalAsset(atPermanentRedirect, '/external-asset', 0, '',
      False, False, '/another-asset', '', '', 0, 0, 0);
    WhenRequest('/external-asset', 'domain.com');
    ThenRequestResultIs(HTTP_PERMANENT_REDIRECT);
    ThenOutHeaderValueIs('Location', 'http://domain.com/another-asset');
    ThenOutContentIsEmpty;

    // Return Not Found when Host header is not provided
    GivenClearServer;
    GivenExternalAsset(atMovedPermanentlyRedirect, '/external-asset', 0, '',
      False, False, '/another-asset', '', '', 0, 0, 0);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentIsEmpty;

    // Redirect to full qualified URL even if Host header is not provided
    GivenClearServer;
    GivenExternalAsset(atTemporaryRedirect, '/external-asset', 0, '',
      False, False, 'https://another-domain.com/asset', '', '', 0, 0, 0);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_TEMPORARYREDIRECT);
    ThenOutHeaderValueIs('Location', 'https://another-domain.com/asset');
    ThenOutContentIsEmpty;

    // External '/404.html' identity content for the 404 responses
    GivenClearServer;
    GivenOptions([bpoDelegateNotFoundTo404]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atContent, '/404.html',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', False, False,
      'identity-content', 'gzip-content', 'brotli-content',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentIs('identity-content');

    // External '/404.html' gzip-compressed content for 404 responses
    GivenClearServer;
    GivenOptions([bpoDelegateNotFoundTo404]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atContent, '/404.html',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', True, False,
      'identity-content', 'gzip-content', 'brotli-content',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentIs('gzip-content');

    // External '/404.html' brotli-compressed content for 404 responses
    GivenClearServer;
    GivenOptions([bpoDelegateNotFoundTo404]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atContent, '/404.html',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', True, True,
      'identity-content', 'gzip-content', 'brotli-content',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentIs('brotli-content');

    // External '/404.html' identity file for the 404 responses
    GivenClearServer;
    GivenOptions([bpoDelegateNotFoundTo404]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atFile, '/404.html',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', False, False,
      RawByteString(NormalizeFileName('Assets\index.html')),
      RawByteString(NormalizeFileName('Assets\index.html.gz')),
      RawByteString(NormalizeFileName('Assets\index.html.br')),
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutHeaderValueIs('Content-Type', 'test-content-type');
    ThenOutContentIsStatic(NormalizeFileName('Assets\index.html'));

    // External '/404.html' gzip-compressed file for the 404 responses
    GivenClearServer;
    GivenOptions([bpoDelegateNotFoundTo404]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atFile, '/404.html',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', True, False,
      RawByteString(NormalizeFileName('Assets\index.html')),
      RawByteString(NormalizeFileName('Assets\index.html.gz')),
      RawByteString(NormalizeFileName('Assets\index.html.br')),
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutHeaderValueIs('Content-Type', 'test-content-type');
    ThenOutContentIsStatic(NormalizeFileName('Assets\index.html.gz'));

    // External '/404.html' brotli-compressed file for the 404 responses
    GivenClearServer;
    GivenOptions([bpoDelegateNotFoundTo404]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atFile, '/404.html',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      'test-content-type', True, True,
      RawByteString(NormalizeFileName('Assets\index.html')),
      RawByteString(NormalizeFileName('Assets\index.html.gz')),
      RawByteString(NormalizeFileName('Assets\index.html.br')),
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutHeaderValueIs('Content-Type', 'test-content-type');
    ThenOutContentIsStatic(NormalizeFileName('Assets\index.html.br'));

    // Redirection on '/404.html' content retrieval
    GivenClearServer;
    GivenOptions([bpoDelegateNotFoundTo404]);
    GivenInHeader('Accept-Encoding', 'gzip, br');
    GivenExternalAsset(atTemporaryRedirect, '/404.html',
      DateTimeToUnixTime(EncodeDate(2000, 1, 2) + EncodeTime(3, 4, 5, 6)),
      '', False, False, 'https://another-domain.com/asset', '', '',
      $12345678, $23456781, $34567812);
    WhenRequest('/external-asset');
    ThenRequestResultIs(HTTP_TEMPORARYREDIRECT);
    ThenOutHeaderValueIs('Location', 'https://another-domain.com/asset');
    ThenOutContentIsEmpty;
  end;
end;

{$IF DEFINED(VER170) OR DEFINED(VER180)}{$HINTS OFF}{$IFEND}
procedure TBoilerplateHTTPServerShould.SupportStaticRoot;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    DeleteFile('static\identity\index.html');
    RemoveDir('static\identity');
    RemoveDir('static');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    WhenRequest('/index.html');
    ThenOutContentIsStaticFile(
      'static\identity\index.html',
      'Assets\index.html');
    DeleteFile('static\identity\index.html');
    RemoveDir('static\identity');
    RemoveDir('static');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutContentIsStaticFile(
      'static\gzip\index.html.gz',
      'Assets\index.html.gz');
    DeleteFile('static\gzip\index.html.gz');
    RemoveDir('static\gzip');
    RemoveDir('static');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenInHeader('Accept-Encoding', 'br');
    WhenRequest('/index.html');
    ThenOutContentIsStaticFile(
      'static\brotli\index.html.br',
      'Assets\index.html.br');
    DeleteFile('static\brotli\index.html.br');
    RemoveDir('static\brotli');
    RemoveDir('static');
  end;
end;
{$IF DEFINED(VER170) OR DEFINED(VER180)}{$HINTS ON}{$IFEND}

procedure TBoilerplateHTTPServerShould.SupportStrictSSLOverHTTP;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLOff);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLOn);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security',
      'max-age=31536000');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLIncludeSubDomains);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security',
      'max-age=31536000; includeSubDomains');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLIncludeSubDomainsPreload);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security',
      'max-age=31536000; includeSubDomains; preload');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportStrictSSLOverHTTPS;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLOff);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLOn);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security', 'max-age=31536000');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLIncludeSubDomains);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security',
      'max-age=31536000; includeSubDomains');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLIncludeSubDomainsPreload);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security',
      'max-age=31536000; includeSubDomains; preload');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportWWWRewrite;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwOff);
    GivenOptions([]);
    WhenRequest('/index.html', 'www.domain.com');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwOff);
    GivenOptions([]);
    WhenRequest('/index.html', 'www.domain.com', True);
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwSuppress);
    WhenRequest('/index.html', 'www.domain.com');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'http://domain.com/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwSuppress);
    WhenRequest('/index.html', 'www.domain.com', True);
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'https://domain.com/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwForce);
    WhenRequest('/index.html', 'domain.com');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'http://www.domain.com/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwForce);
    WhenRequest('/index.html', 'domain.com', True);
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'https://www.domain.com/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);
  end;
end;

procedure TBoilerplateHTTPServerShould.UnregisterCustomOptions;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index.html', [bpoSetCacheNoCache]);
    UnregisterCustomOptions('/index.html');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index.html', [bpoSetCacheNoCache]);
    RegisterCustomOptions('/404.html', [bpoSetCacheNoCache]);
    UnregisterCustomOptions(TRawUTF8DynArrayFrom(['/index.html', '/404.html']));
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index*', [bpoSetCacheNoCache]);
    UnregisterCustomOptions('/index*');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
  end;
end;

procedure TBoilerplateHTTPServerShould.UpdateStaticAsset;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenStaticFile('/index.html');
    GivenModifiedFile('static\identity\index.html', True, True);
    WhenRequest('/index.html');
    ThenFileTimestampAndSizeAreEqualToAsset(
      'static\identity\index.html', '/index.html');
    ThenFileContentIsNotEqualToAsset(
      'static\identity\index.html', '/index.html');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenStaticFile('/index.html');
    GivenModifiedFile('static\identity\index.html', False, True);
    WhenRequest('/index.html');
    ThenFileContentIsEqualToAsset(
      'static\identity\index.html', '/index.html');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenStaticFile('/index.html');
    GivenModifiedFile('static\identity\index.html', True, False);
    WhenRequest('/index.html');
    ThenFileContentIsEqualToAsset(
      'static\identity\index.html', '/index.html');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenStaticFile('/index.html');
    GivenModifiedFile('static\identity\index.html', False, False);
    WhenRequest('/index.html');
    ThenFileContentIsEqualToAsset(
      'static\identity\index.html', '/index.html');

    DeleteFile('static\identity\index.html');
    RemoveDir('static\identity');
    RemoveDir('static');
  end;
end;

procedure TBoilerplateHTTPServerShould.CallInherited;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    WhenRequest;
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.Delegate404ToInherited_404;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBadRequestTo404]);
    WhenRequest('123456', 'localhost');
    ThenOutContentEqualsFile('Assets\404.html');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBadRequestTo404, bpoDelegate404ToInherited_404]);
    WhenRequest('', 'localhost');
    ThenOutContentIs('404 NOT FOUND');
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateBadRequestTo404;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('root/12345');
    ThenRequestResultIs(HTTP_BADREQUEST);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBadRequestTo404]);
    WhenRequest('root/12345');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentEqualsFile('Assets\404.html');
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateBlocked;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    GivenAssets;
    WhenRequest('/sample.conf');
    ThenOutContentEqualsFile('Assets\sample.conf');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBlocked]);
    WhenRequest('/sample.conf');
    ThenOutContentEqualsFile('Assets\404.html');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html~');
    ThenOutContentEqualsFile('Assets\index.html~');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBlocked]);
    WhenRequest('/index.html~');
    ThenOutContentEqualsFile('Assets\404.html');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html#');
    ThenOutContentEqualsFile('Assets\index.html#');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBlocked]);
    WhenRequest('/index.html#');
    ThenOutContentEqualsFile('Assets\404.html');
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateForbiddenTo404;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self, True));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('root/12345');
    ThenRequestResultIs(HTTP_FORBIDDEN);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateForbiddenTo404]);
    WhenRequest('root/12345');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentEqualsFile('Assets\404.html');
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateHidden;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    GivenAssets;
    WhenRequest('/.hidden/sample.txt');
    ThenOutContentEqualsFile('Assets\.hidden\sample.txt');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateHidden]);
    WhenRequest('/.hidden/sample.txt');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenOptions([]);
    GivenAssets;
    WhenRequest('/img/.hidden/marmot.jpg');
    ThenOutContentEqualsFile('Assets\img\.hidden\marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateHidden]);
    WhenRequest('/img/.hidden/marmot.jpg');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateHidden]);
    WhenRequest('/.well-known/acme-challenge/sample.txt');
    ThenOutContentEqualsFile('Assets\.well-known\acme-challenge\sample.txt');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/.well-known/.hidden/sample.txt');
    ThenOutContentEqualsFile('Assets\.well-known\.hidden\sample.txt');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateHidden]);
    WhenRequest('/.well-known/.hidden/sample.txt');
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateNotAcceptableTo404;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(
    Self, False, T404Application.Create));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    GivenCustomStatus(HTTP_NOTACCEPTABLE);
    WhenRequest('root/Record/1');
    ThenRequestResultIs(HTTP_NOTACCEPTABLE);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateNotAcceptableTo404]);
    WhenRequest('root/Record/1');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentEqualsFile('Assets\404.html');
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateNotAllowedTo404;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(
    Self, False, T404Application.Create));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('root/Record/1');
    ThenRequestResultIs(HTTP_NOTALLOWED);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateNotAllowedTo404]);
    WhenRequest('root/Record/1');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentEqualsFile('Assets\404.html');
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateNotFoundTo404;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/12345');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateNotFoundTo404]);
    WhenRequest('/12345');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentEqualsFile('Assets\404.html');
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateRootToIndex;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('');
    ThenOutContentIs('');
    ThenRequestResultIs(HTTP_BADREQUEST);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/');
    ThenOutContentIs('');
    ThenRequestResultIs(HTTP_BADREQUEST);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateRootToIndex]);
    WhenRequest('');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateRootToIndex]);
    WhenRequest('/');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateUnauthorizedTo404;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(
    Self, False, T404Application.Create));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    GivenCustomStatus(HTTP_UNAUTHORIZED);
    WhenRequest('root/Record/1');
    ThenRequestResultIs(HTTP_UNAUTHORIZED);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateUnauthorizedTo404]);
    WhenRequest('root/Record/1');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentEqualsFile('Assets\404.html');
  end;
end;

procedure TBoilerplateHTTPServerShould.DeleteServerInternalState;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    GivenOutHeader('Server-InternalState', '1');
    WhenRequest('');
    ThenOutHeaderValueIs('Server-InternalState', '1');

    GivenClearServer;
    GivenOptions([bpoDeleteServerInternalState]);
    GivenOutHeader('Server-InternalState', '1');
    WhenRequest('');
    ThenOutHeaderValueIs('Server-InternalState', '');
  end;
end;

procedure TBoilerplateHTTPServerShould.DeleteXPoweredBy;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    GivenOutHeader('X-Powered-By', '123');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Powered-By', '123');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDeleteXPoweredBy]);
    GivenOutHeader('X-Powered-By', '123');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Powered-By', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.DisableTRACEMethod;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html', '', False, 'TRACE');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDisableTRACEMethod]);
    WhenRequest('/index.html', '', False, 'TRACE');
    ThenRequestResultIs(HTTP_NOTALLOWED);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableCacheBusting;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html?123');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheBusting]);
    WhenRequest('/index.html?123');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableCacheBustingBeforeExt;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.xyz123.html');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheBustingBeforeExt]);
    WhenRequest('/index.xyz123.html');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableCacheByETag;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
  Hash: RawUTF8;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    Hash := FormatUTF8('"%"',
      [crc32cUTF8ToHex(GetFileContent('Assets\index.html'))]);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('ETag', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    GivenInHeader('If-None-Match', Hash);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('ETag', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheByETag]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('ETag', Hash);
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheByETag]);
    GivenInHeader('If-None-Match', Hash);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('ETag', '');
    ThenOutContentIsEmpty;
    ThenRequestResultIs(HTTP_NOTMODIFIED);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableCacheByLastModified;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
  LastModified: RawUTF8;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;

    LastModified := UnixTimeToHTTPDate(FAssets.Find('/index.html').Timestamp);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Last-Modified', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    GivenInHeader('If-Modified-Since', LastModified);
    WhenRequest('/index.html');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenOutHeaderValueIs('Last-Modified', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheByLastModified]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Last-Modified', LastModified);
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheByLastModified]);
    GivenInHeader('If-Modified-Since', LastModified);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Last-Modified', '');
    ThenOutContentIsEmpty;
    ThenRequestResultIs(HTTP_NOTMODIFIED);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableReferrerPolicy;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Referrer-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Referrer-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Referrer-Policy', 'strict-origin-when-cross-origin');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    WhenRequest('/sample.css');
    ThenOutHeaderValueIs('Referrer-Policy', 'strict-origin-when-cross-origin');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    WhenRequest('/sample.js');
    ThenOutHeaderValueIs('Referrer-Policy', 'strict-origin-when-cross-origin');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    WhenRequest('/sample.xml');
    ThenOutHeaderValueIs('Referrer-Policy', 'strict-origin-when-cross-origin');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    WhenRequest('/sample.pdf');
    ThenOutHeaderValueIs('Referrer-Policy', 'strict-origin-when-cross-origin');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Referrer-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    GivenReferrerPolicy('custom-referrer-policy');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Referrer-Policy', 'custom-referrer-policy');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    GivenReferrerPolicy('custom-referrer-policy');
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Referrer-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableXSSFilter;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-XSS-Protection', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-XSS-Protection', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableXSSFilter]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-XSS-Protection', '1; mode=block');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableXSSFilter]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-XSS-Protection', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.FixMangledAcceptEncoding;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoFixMangledAcceptEncoding]);
    GivenInHeader('Accept-EncodXng', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoFixMangledAcceptEncoding]);
    GivenInHeader('X-cept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceGZipHeader;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/sample.svgz');
    ThenOutHeaderValueIs('Content-Encoding', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceGZipHeader]);
    WhenRequest('/sample.svgz');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenOutContentEqualsFile('Assets\sample.svgz');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceHTTPS;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html', 'localhost');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS]);
    WhenRequest('/index.html', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'https://localhost/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceHTTPSExceptLetsEncrypt;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([bpoForceHTTPS]);
    GivenAssets;
    WhenRequest('/.well-known/acme-challenge/sample.txt', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location',
      'https://localhost/.well-known/acme-challenge/sample.txt');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS]);
    WhenRequest('/.well-known/cpanel-dcv/sample.txt', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location',
      'https://localhost/.well-known/cpanel-dcv/sample.txt');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS]);
    WhenRequest('/.well-known/pki-validation/sample.txt', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location',
      'https://localhost/.well-known/pki-validation/sample.txt');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS, bpoForceHTTPSExceptLetsEncrypt]);
    WhenRequest('/.well-known/acme-challenge/sample.txt');
    {$IFDEF LINUX}
    // .well-known directory is hidden on linux and was not included into Assets
    // ThenRequestResultIs(HTTP_NOTFOUND);
    {$ELSE}
    ThenOutContentIs('acme challenge sample');
    ThenRequestResultIs(HTTP_SUCCESS);
    {$ENDIF}

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS, bpoForceHTTPSExceptLetsEncrypt]);
    WhenRequest('/.well-known/cpanel-dcv/sample.txt');
    {$IFDEF LINUX}
    // .well-known directory is hidden on linux and was not included into Assets
    // ThenRequestResultIs(HTTP_NOTFOUND);
    {$ELSE}
    ThenOutContentIs('cpanel dcv sample');
    ThenRequestResultIs(HTTP_SUCCESS);
    {$ENDIF}

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS, bpoForceHTTPSExceptLetsEncrypt]);
    WhenRequest('/.well-known/pki-validation/sample.txt');
    {$IFDEF LINUX}
    // .well-known directory is hidden on linux and was not included into Assets
    // ThenRequestResultIs(HTTP_NOTFOUND);
    {$ELSE}
    ThenOutContentIs('pki validation sample');
    ThenRequestResultIs(HTTP_SUCCESS);
    {$ENDIF}
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateIndexToInheritedDefault;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateRootToIndex]);
    WhenRequest('', 'localhost');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateRootToIndex, bpoDelegateIndexToInheritedDefault]);
    WhenRequest('', 'localhost');
    ThenOutContentIs('DEFAULT CONTENT');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateIndexToInheritedDefaultOverSSL;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps,
    TBoilerplateHTTPServerSteps.Create(Self, False, nil, True));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateRootToIndex, bpoDelegateIndexToInheritedDefault]);
    WhenRequest('', 'localhost', True);
    ThenOutContentIs('DEFAULT CONTENT');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceMIMEType;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.geojson');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.geojson');
    ThenOutContentTypeIs('application/geo+json');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.rdf');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.rdf');
    ThenOutContentTypeIs('application/rdf+xml');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.xml');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.xml');
    ThenOutContentTypeIs('application/xml');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.mjs');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.mjs');
    ThenOutContentTypeIs('text/javascript');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.js');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.js');
    ThenOutContentTypeIs('text/javascript');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.wasm');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.wasm');
    ThenOutContentTypeIs('application/wasm');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.woff');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.woff');
    ThenOutContentTypeIs('font/woff');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.woff2');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.woff2');
    ThenOutContentTypeIs('font/woff2');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.ttf');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.ttf');
    ThenOutContentTypeIs('font/ttf');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.ttc');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.ttc');
    ThenOutContentTypeIs('font/collection');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.otf');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.otf');
    ThenOutContentTypeIs('font/otf');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.ics');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.ics');
    ThenOutContentTypeIs('text/calendar');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.md');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.md');
    ThenOutContentTypeIs('text/markdown');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.markdown');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.markdown');
    ThenOutContentTypeIs('text/markdown');
  end;
end;


procedure TBoilerplateHTTPServerShould.LoadAndReturnAssets;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutContentEqualsFile('Assets\img\marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg', '', False, 'HEAD');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg', '', False, 'POST');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg', '', False, 'PUT');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg', '', False, 'DELETE');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg', '', False, 'CONNECT');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg', '', False, 'OPTIONS');
    ThenRequestResultIs(HTTP_NOCONTENT);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg', '', False, 'TRACE');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg', '', False, 'PATCH');
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.PreventMIMESniffing;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Content-Type-Options', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoPreventMIMESniffing]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Content-Type-Options', 'nosniff');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.RedirectInInherited_404;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self, False,
    T404Application.Create));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([bpoDelegateBadRequestTo404, bpoDelegate404ToInherited_404]);
    WhenRequest('123456', 'localhost');
    ThenApp404Called;
  end;
end;

procedure TBoilerplateHTTPServerShould.RegisterCustomOptions;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index.html', [bpoSetCacheNoCache]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    WhenRequest('/404.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index.html', [bpoSetCacheNoCache]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions(
      TRawUTF8DynArrayFrom(['/index.html', '/404.html']), [bpoSetCacheNoCache]);
    WhenRequest('/404.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index*', [bpoSetCacheNoCache]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceTextUTF8Charset;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/index.html');
    ThenOutContentTypeIs('text/html');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/index.txt');
    ThenOutContentTypeIs('text/plain');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType, bpoForceTextUTF8Charset]);
    WhenRequest('/index.html');
    ThenOutContentTypeIs('text/html; charset=UTF-8');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType, bpoForceTextUTF8Charset]);
    WhenRequest('/index.txt');
    ThenOutContentTypeIs('text/plain; charset=UTF-8');
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceUTF8Charset;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/data.webmanifest');
    ThenOutContentTypeIs('application/manifest+json');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType, bpoForceUTF8Charset]);
    WhenRequest('/data.webmanifest');
    ThenOutContentTypeIs('application/manifest+json; charset=UTF-8');
  end;
end;

procedure TBoilerplateHTTPServerShould.ServeExactCaseURL;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    WhenRequest('/img/marmot.JPG', 'localhost');
    ThenOutContentEqualsFile('Assets\img\marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenServeExactCaseURL;
    WhenRequest('/img/marmot.JPG', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'http://localhost/img/marmot.jpg');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenServeExactCaseURL;
    WhenRequest('/img/marmot.JPG', 'localhost', True);
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'https://localhost/img/marmot.jpg');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetCacheMaxAge;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=0');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('*=12');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=12');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=10');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=10');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=15s');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=15');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=20S');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=20');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=25h');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [25 * SecsPerHour]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=30H');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [30 * SecsPerHour]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=35d');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [35 * SecsPerDay]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=40D');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [40 * SecsPerDay]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=45w');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [45 * 7 * SecsPerDay]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=50W');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [50 * 7 * SecsPerDay]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=6m');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [6 * 2629746]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=7M');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [7 * 2629746]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=8y');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [8 * 12 * 2629746]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=9Y');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [9 * 12 * 2629746]));
  end;
end;

procedure TBoilerplateHTTPServerShould.SetCacheNoTransform;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetCachePublic;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCachePublic]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'public');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCachePrivate]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'private');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoCache]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoStore]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'no-store');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMustRevalidate]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'must-revalidate');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCachePublic]);
    GivenOutHeader('Cache-Control', 'max-age=0');
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=0, public');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetExpires;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
  LExpires: RawUTF8;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', '');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('*=12');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 12);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=10');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 10);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=15s');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 15);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=20S');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 20);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=25h');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 25 * SecsPerHour);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=30H');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 30 * SecsPerHour);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=35d');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 35 * SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=40D');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 40 * SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=45w');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 45 * 7 * SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=50W');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 50 * 7 * SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=6m');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 6 * 2629746);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=7M');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 7 * 2629746);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=8y');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 8 * 12 * 2629746);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=9Y');
    LExpires := UnixTimeToHTTPDate(UnixTimeUTC + 9 * 12 * 2629746);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetVaryAcceptEncoding;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Vary', '');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoVaryAcceptEncoding]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Vary', 'Accept-Encoding');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoVaryAcceptEncoding]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Vary', '');

    GivenClearServer;
    GivenOptions([bpoDelegateIndexToInheritedDefault]);
    GivenAssets;
    WhenRequest('/default', 'localhost');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('Vary', '');

    GivenClearServer;
    GivenOptions([bpoDelegateIndexToInheritedDefault, bpoVaryAcceptEncoding]);
    GivenAssets;
    WhenRequest('/default', 'localhost');
    ThenRequestResultIs(HTTP_SUCCESS);
    ThenOutHeaderValueIs('Vary', 'Accept-Encoding');
  end;
end;

procedure TBoilerplateHTTPServerShould.SetXFrameOptions;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Frame-Options', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-Frame-Options', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXFrameOptions]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Frame-Options', 'DENY');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXFrameOptions]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-Frame-Options', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetXUACompatible;
var
  Auto: IAutoFree;
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-UA-Compatible', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-UA-Compatible', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXUACompatible]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-UA-Compatible', 'IE=edge');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXUACompatible]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-UA-Compatible', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXUACompatible, bpoDelegateNotFoundTo404]);
    WhenRequest('/404');
    ThenOutHeaderValueIs('X-UA-Compatible', 'IE=edge');
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TCSP2Should.SupportSourceList;
var
  CSP: TCSP2;
  Value: RawByteString;
  Nonce, Hash: SockString;
  Hash256: THash256;
  Hash384: THash384;
  Hash512: THash512;
begin
  Check(
    CSP.Init.DefaultSrc.Add('x').CSP.Policy =
    'default-src x',
    'SourceList: Add');

  Check(
    CSP.Init.DefaultSrc.Add('x').Add('y').Add('z').CSP.Policy =
    'default-src x y z',
    'SourceList: Several values');

  Check(
    CSP.Init.DefaultSrc.None.CSP.Policy =
    'default-src ''none''',
    'SourceList: None');

  Check(
    CSP.Init.DefaultSrc.Any.None.CSP.Policy =
    'default-src ''none''',
    'SourceList: None on non-empty list');

  Check(
    CSP.Init.DefaultSrc.Null.CSP.Policy =
    'default-src null',
    'SourceList: Null');

  Check(
    CSP.Init.DefaultSrc.Any.CSP.Policy =
    'default-src *',
    'SourceList: Any');

  Check(
    CSP.Init.DefaultSrc.Scheme('https').CSP.Policy =
    'default-src https:',
    'SourceList: Scheme');

  Check(
    CSP.Init.DefaultSrc.Host('', 'example.com', '', '').CSP.Policy =
    'default-src example.com',
    'SourceList: Host');

  Check(
    CSP.Init.DefaultSrc.Host('https', 'example.com', '', '').CSP.Policy =
    'default-src https://example.com',
    'SourceList: Host, Scheme');

  Check(
    CSP.Init.DefaultSrc.Host('', 'example.com', '8080', '').CSP.Policy =
    'default-src example.com:8080',
    'SourceList: Host, Port');

  Check(
    CSP.Init.DefaultSrc.Host('', 'example.com', '', '/now').CSP.Policy =
    'default-src example.com/now',
    'SourceList: Host, Path');

  Check(
    CSP.Init.DefaultSrc.Host('', 'example.com', '8080', '/now').CSP.Policy =
    'default-src example.com:8080/now',
    'SourceList: Host, Port, Path');

  Check(
    CSP.Init.DefaultSrc.Host('https', 'example.com', '8080', '/now').CSP.Policy =
    'default-src https://example.com:8080/now',
    'SourceList: Scheme, Host, Port, Path');

  Check(
    CSP.Init.DefaultSrc.Host('https://example.com:8080/now').CSP.Policy =
    'default-src https://example.com:8080/now',
    'SourceList: Raw Host');

  Check(
    CSP.Init.DefaultSrc.WithSelf.CSP.Policy =
    'default-src ''self''',
    'SourceList: WithSelf');

  Check(
    CSP.Init.DefaultSrc.UnsafeInline.CSP.Policy =
    'default-src ''unsafe-inline''',
    'SourceList: UnsafeInline');

  Check(
    CSP.Init.DefaultSrc.UnsafeEval.CSP.Policy =
    'default-src ''unsafe-eval''',
    'SourceList: UnsafeEval');

  Value := CSP.Init.DefaultSrc.NonceLen(Nonce).CSP.Policy;
  Check(
    Copy(Value, 1, Length('default-src ''nonce-')) = 'default-src ''nonce-',
    'SourceList: Nonce prefix');
  Delete(Value, 1, Length('default-src ''nonce-'));
  Check(
    Copy(Value, Length(Value), 1) = '''',
    'SourceList: Nonce postfix');
  Delete(Value, Length(Value), 1);
  Check(Value = Nonce, 'SourceList: Nonce');

  Value := CSP.Init.DefaultSrc.NonceLen(Nonce, 128).CSP.Policy;
  Delete(Value, 1, Length('default-src ''nonce-'));
  Delete(Value, Length(Value), 1);
  Check(Length(Base64ToBin(Value)) = 128 shr 3,
    'SourceList: Nonce with custom length');

  Value := CSP.Init.DefaultSrc.Nonce('test-nonce').CSP.Policy;
  Check(
    Copy(Value, 1, Length('default-src ''nonce-')) = 'default-src ''nonce-',
    'SourceList: Nonce by value prefix');
  Delete(Value, 1, Length('default-src ''nonce-'));
  Check(
    Copy(Value, Length(Value), 1) = '''',
    'SourceList: Nonce by value postfix');
  Delete(Value, Length(Value), 1);
  Check(
    Base64ToBin(Value) = 'test-nonce',
    'SourceList: Nonce by value');

  Check(
    CSP.Init.DefaultSrc.Nonce64('test').CSP.Policy =
    'default-src ''nonce-test''',
    'SourceList: Raw Nonce');

  Check(
    CSP.Init.DefaultSrc.SHA256('alert(''Hello, world.'');', @Hash).CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=']),
    'SourceList: SHA256');
  Check(Hash = 'qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=',
    'SourceList: SHA256 Hash');

  Value := HexToBin(
    'ab39cb72c44ec7818008fd9d9b450228' +
    '2cc21be1e267582eaba6590e86ff4e78');
  Move(Value[1], Hash256, SizeOf(THash256));
  Check(
    CSP.Init.DefaultSrc.SHA256Hash(Hash256).CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=']),
    'SourceList: SHA256Hash from THash256');

  Value := HexToBin(
    'ab39cb72c44ec7818008fd9d9b450228' +
    '2cc21be1e267582eaba6590e86ff4e78');
  Check(
    CSP.Init.DefaultSrc.SHA256Hash(Value).CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=']),
    'SourceList: SHA256Hash from RawByteString');

  Check(
    CSP.Init.DefaultSrc.SHA256Hash64(
      'qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=').CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=']),
    'SourceList: SHA256Hash64');

  Check(
    CSP.Init.DefaultSrc.SHA384('alert(''Hello, world.'');', @Hash).CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO']),
    'SourceList: SHA384');
  Check(Hash =
    'H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO',
    'SourceList: SHA384 Hash');

  Value := HexToBin(
    '1fc05187c8f8f0ef6861ab5fbb9019ceae80f5120d8593b9'+
    '1f5e9d4199e02bb4fad9e9bc314b7514b9b9dadf9e5fac4e');
  Move(Value[1], Hash384, SizeOf(THash384));
  Check(
    CSP.Init.DefaultSrc.SHA384Hash(Hash384).CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO']),
    'SourceList: SHA384Hash from THash384');

  Value := HexToBin(
    '1fc05187c8f8f0ef6861ab5fbb9019ceae80f5120d8593b9'+
    '1f5e9d4199e02bb4fad9e9bc314b7514b9b9dadf9e5fac4e');
  Check(
    CSP.Init.DefaultSrc.SHA384Hash(Value).CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO']),
    'SourceList: SHA384Hash from RawByteString');

  Check(
    CSP.Init.DefaultSrc.SHA384Hash64(
      'H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO')
      .CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO']),
    'SourceList: SHA384Hash64');

  Check(
    CSP.Init.DefaultSrc.SHA512('alert(''Hello, world.'');', @Hash).CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==']),
    'SourceList: SHA512');
  Check(Hash =
    'Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
    '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==',
    'SourceList: SHA512 Hash');

  Value := HexToBin(
    '4366c54ce84400b90df213a6b3614a4c32f2edeba03f6cc56754fc2c2bd7e361' +
    '69dd6a0daf76e365200778eb07adb57516ef7f0341330a29d113b01fd687cfaf');
  Move(Value[1], Hash512, SizeOf(THash512));
  Check(
    CSP.Init.DefaultSrc.SHA512Hash(Hash512).CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==']),
    'SourceList: SHA512Hash from THash512');

  Value := HexToBin(
    '4366c54ce84400b90df213a6b3614a4c32f2edeba03f6cc56754fc2c2bd7e361' +
    '69dd6a0daf76e365200778eb07adb57516ef7f0341330a29d113b01fd687cfaf');
  Check(
    CSP.Init.DefaultSrc.SHA512Hash(Value).CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==']),
    'SourceList: SHA512Hash from RawByteString');

  Check(
    CSP.Init.DefaultSrc.SHA512Hash64(
      'Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
      '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==').CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==']),
    'SourceList: SHA512Hash64');
end;

procedure TCSP2Should.SupportFrameAncestors;
var
  CSP: TCSP2;
  FrameAncestors: TCSP2FrameAncestors;
begin
  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Add('x');
  Check(CSP.Policy = 'frame-ancestors x', 'FrameAncestors: Add');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Add('x').Add('y').Add('z');
  Check(CSP.Policy = 'frame-ancestors x y z', 'FrameAncestors: Several values');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.None;
  Check(CSP.Policy = 'frame-ancestors ''none''', 'FrameAncestors: None');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Scheme('https').None;
  Check(CSP.Policy = 'frame-ancestors ''none''',
    'FrameAncestors: None on non-empty list');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Scheme('https');
  Check(CSP.Policy = 'frame-ancestors https:', 'FrameAncestors: Scheme');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('', 'example.com', '', '');
  Check(CSP.Policy = 'frame-ancestors example.com', 'FrameAncestors: Host');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('https', 'example.com', '', '');
  Check(CSP.Policy = 'frame-ancestors https://example.com',
    'FrameAncestors: Host, Scheme');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('', 'example.com', '8080', '');
  Check(CSP.Policy = 'frame-ancestors example.com:8080',
    'FrameAncestors: Host, Port');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('', 'example.com', '', '/now');
  Check(CSP.Policy = 'frame-ancestors example.com/now',
    'FrameAncestors: Host, Path');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('', 'example.com', '8080', '/now');
  Check(CSP.Policy = 'frame-ancestors example.com:8080/now',
    'FrameAncestors: Host, Port, Path');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('https', 'example.com', '8080', '/now');
  Check(CSP.Policy = 'frame-ancestors https://example.com:8080/now',
    'FrameAncestors: Scheme, Host, Port, Path');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('https://example.com:8080/now');
  Check(CSP.Policy = 'frame-ancestors https://example.com:8080/now',
    'FrameAncestors: Raw Host');
end;

procedure TCSP2Should.SupportHTTPHeaders;
var
  CSP: TCSP2;
begin
  Check(
    CSP.Init.DefaultSrc.WithSelf.CSP.HTTPHeader =
    'Content-Security-Policy: default-src ''self'''#$D#$A,
    'HTTPHeaders: CSP');

  Check(
    CSP.Init.DefaultSrc.WithSelf.CSP.HTTPHeaderReportOnly =
    'Content-Security-Policy-Report-Only: default-src ''self'''#$D#$A,
    'HTTPHeaders: CSP Reports Only');
end;

procedure TCSP2Should.SupportMediaTypeList;
var
  CSP: TCSP2;
  PluginTypes: TCSP2MediaTypeList;
begin
  PluginTypes := CSP.Init.PluginTypes;
  PluginTypes.Add('x');
  Check(CSP.Policy = 'plugin-types x', 'MediaTypeList: Add');

  PluginTypes := CSP.Init.PluginTypes;
  PluginTypes.Add('x').Add('y').Add('z');
  Check(CSP.Policy = 'plugin-types x y z', 'MediaTypeList: Several values');

  PluginTypes := CSP.Init.PluginTypes;
  PluginTypes.MediaType('application', 'json');
  Check(CSP.Policy = 'plugin-types application/json',
    'MediaTypeList: MediaType');
end;

procedure TCSP2Should.SupportURIReferences;
var
  CSP: TCSP2;
  ReportURI: TCSP2URIReferences;
begin
  ReportURI := CSP.Init.ReportURI;
  ReportURI.Add('x');
  Check(CSP.Policy = 'report-uri x', 'URIReferences: Add');

  ReportURI := CSP.Init.ReportURI;
  ReportURI.Add('x').Add('y').Add('z');
  Check(CSP.Policy = 'report-uri x y z', 'URIReferences: Several values');

  ReportURI := CSP.Init.ReportURI;
  ReportURI.Reference('/csp-violation/');
  Check(CSP.Policy = 'report-uri /csp-violation/', 'URIReferences: MediaType');
end;

procedure TCSP2Should.SupportSandboxTokens;
var
  CSP: TCSP2;
  Sandbox: TCSP2SandboxTokens;
begin
  Sandbox := CSP.Init.Sandbox;
  Sandbox.Add('x');
  Check(CSP.Policy = 'sandbox x', 'SandboxTokens: Add');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.Add('x').Add('y').Add('z');
  Check(CSP.Policy = 'sandbox x y z', 'SandboxTokens: Several values');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.Empty;
  Check(CSP.Policy = 'sandbox', 'SandboxTokens: Empty');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.Add('x').Empty;
  Check(CSP.Policy = 'sandbox', 'SandboxTokens: Empty on non-empty list');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowForms;
  Check(CSP.Policy = 'sandbox allow-forms', 'SandboxTokens: AllowForms');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowPointerLock;
  Check(CSP.Policy = 'sandbox allow-pointer-lock',
    'SandboxTokens: AllowPointerLock');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowPopups;
  Check(CSP.Policy = 'sandbox allow-popups', 'SandboxTokens: AllowPopups');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowSameOrigin;
  Check(CSP.Policy = 'sandbox allow-same-origin',
    'SandboxTokens: AllowSameOrigin');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowScripts;
  Check(CSP.Policy = 'sandbox allow-scripts', 'SandboxTokens: AllowScripts');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowTopNavigation;
  Check(CSP.Policy = 'sandbox allow-top-navigation',
    'SandboxTokens: AllowTopNavigation');
end;

procedure TCSP2Should.SupportDirectives;
var
  CSP: TCSP2;
  Index: Integer;
  Value: SockString;
  FrameAncestors: TCSP2FrameAncestors;
  PluginTypes: TCSP2MediaTypeList;
  ReportURI: TCSP2URIReferences;
  Sandbox: TCSP2SandboxTokens;
begin
  Check(
    CSP.Init.BaseURI.Any.
    CSP.DefaultSrc.WithSelf.
    CSP.Policy =
    'base-uri *; default-src ''self''',
    'CSP: Several directives');

  Check(
    CSP.Init.DefaultSrc.Add(';').CSP.Policy =
    'default-src %3B',
    'CSP: Replaces Semicolon to %3B');

  Check(
    CSP.Init.DefaultSrc.Add(',').CSP.Policy =
    'default-src %2C',
    'CSP: Replaces Comma to %2C');

  CSP.Init;
  SetLength(Value, 10000 * 2);
  for Index := 0 to Length(Value) div 2 - 1 do
  begin
    CSP.DefaultSrc.Add('*');
    Value[Index * 2 + 1] := '*';
    Value[Index * 2 + 2] := ' ';
  end;
  Check(
    CSP.Policy =
    SynCommons.TrimRight('default-src ' + Value),
    'CSP: Large list');

  Check(
    CSP.Init.BaseURI.Any.CSP.Policy =
    'base-uri *',
    'CSP: BaseURI');

  Check(
    CSP.Init.ChildSrc.Any.CSP.Policy =
    'child-src *',
    'CSP: ChildSrc');

  Check(
    CSP.Init.ConnectSrc.Any.CSP.Policy =
    'connect-src *',
    'CSP: ConnectSrc');

  Check(
    CSP.Init.DefaultSrc.Any.CSP.Policy =
    'default-src *',
    'CSP: DefaultSrc');

  Check(
    CSP.Init.FontSrc.Any.CSP.Policy =
    'font-src *',
    'CSP: FontSrc');

  Check(
    CSP.Init.FormAction.Any.CSP.Policy =
    'form-action *',
    'CSP: FormAction');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.None;
  Check(CSP.Policy = 'frame-ancestors ''none''', 'CSP: FrameAncestors');

  Check(
    CSP.Init.ImgSrc.Any.CSP.Policy =
    'img-src *',
    'CSP: ImgSrc');

  Check(
    CSP.Init.MediaSrc.Any.CSP.Policy =
    'media-src *',
    'CSP: MediaSrc');

  Check(
    CSP.Init.ObjectSrc.Any.CSP.Policy =
    'object-src *',
    'CSP: ObjectSrc');

  PluginTypes := CSP.Init.PluginTypes;
  PluginTypes.MediaType('application', 'json');
  Check(CSP.Policy = 'plugin-types application/json', 'CSP: PluginTypes');

  ReportURI := CSP.Init.ReportURI;
  ReportURI.Reference('/csp-violation/');
  Check(CSP.Policy = 'report-uri /csp-violation/', 'CSP: ReportURI');

  Sandbox := CSP.init.Sandbox;
  Sandbox.Empty;
  Check(CSP.Policy = 'sandbox', 'CSP: Sandbox');

  Check(
    CSP.Init.ScriptSrc.Any.CSP.Policy =
    'script-src *',
    'CSP: ScriptSrc');

  Check(
    CSP.Init.StyleSrc.Any.CSP.Policy =
    'style-src *',
    'CSP: StyleSrc');
end;

procedure TCSP2Should.SupportExamples;
var
  CSP: TCSP2;
  Nonce: SockString;
begin
  Check(
    CSP.Init.DefaultSrc.WithSelf.CSP.HTTPHeader =
    'Content-Security-Policy: default-src ''self'''#$D#$A,
    'Example: #1');

  Check(
    CSP.Init.DefaultSrc.WithSelf.
    CSP.ImgSrc.Any.
    CSP.ObjectSrc.
      Host('media1.example.com').
      Host('media2.example.com').
      Host('*.cdn.example.com').
    CSP.ScriptSrc.Host('trustedscripts.example.com').
    CSP.HTTPHeader =
    'Content-Security-Policy: ' +
      'default-src ''self''; ' +
      'img-src *; ' +
      'object-src media1.example.com media2.example.com *.cdn.example.com; ' +
      'script-src trustedscripts.example.com' +
      #$D#$A,
    'Example: #2');

  Check(
    CSP.Init.DefaultSrc.WithSelf.
    CSP.ImgSrc.Any.
    CSP.ObjectSrc.
      Host('media1.example.com').
      Host('media2.example.com').
      Host('*.cdn.example.com').
    CSP.ScriptSrc.Host('trustedscripts.example.com').
    CSP.HTTPHeader =
    'Content-Security-Policy: ' +
      'default-src ''self''; ' +
      'img-src *; ' +
      'object-src media1.example.com media2.example.com *.cdn.example.com; ' +
      'script-src trustedscripts.example.com' +
      #$D#$A,
    'Example: #2');

  Check(
    CSP.Init.DefaultSrc.Scheme('https').UnsafeInline.UnsafeEval.CSP.HTTPHeader =
    'Content-Security-Policy: ' +
      'default-src https: ''unsafe-inline'' ''unsafe-eval'''#$D#$A,
    'Example: #3');

  CSP.Init.ScriptSrc.NonceLen(Nonce);
  Check(
    CSP.Init.ScriptSrc.WithSelf.Nonce64(Nonce).CSP.HTTPHeader =
      FormatUTF8('Content-Security-Policy: ' +
        'script-src ''self'' ''nonce-%'''#$D#$A, [Nonce]),
    'Example: #4');
end;

procedure TCSP3Should.SupportDirectives;
var
  CSP: TCSP3;
  Index: Integer;
  Value: SockString;
  PluginTypes: TCSP3MediaTypeList;
  Sandbox: TCSP3SandboxTokens;
  FrameAncestors: TCSP3FrameAncestors;
begin
  Check(
    CSP.Init.BaseURI.Any.
    CSP.DefaultSrc.WithSelf.
    CSP.Policy =
    'default-src ''self''; base-uri *',
    'CSP: Several directives');

  Check(
    CSP.Init.DefaultSrc.Add(';').CSP.Policy =
    'default-src %3B',
    'CSP: Replaces Semicolon to %3B');

  Check(
    CSP.Init.DefaultSrc.Add(',').CSP.Policy =
    'default-src %2C',
    'CSP: Replaces Comma to %2C');

  CSP.Init;
  SetLength(Value, 10000 * 2);
  for Index := 0 to Length(Value) div 2 - 1 do
  begin
    CSP.DefaultSrc.Add('*');
    Value[Index * 2 + 1] := '*';
    Value[Index * 2 + 2] := ' ';
  end;
  Check(
    CSP.Policy =
    SynCommons.TrimRight('default-src ' + Value),
    'CSP: Large list');

  Check(
    CSP.Init.ChildSrc.Any.CSP.Policy =
    'child-src *',
    'CSP: ChildSrc');

  Check(
    CSP.Init.ConnectSrc.Any.CSP.Policy =
    'connect-src *',
    'CSP: ConnectSrc');

  Check(
    CSP.Init.DefaultSrc.Any.CSP.Policy =
    'default-src *',
    'CSP: DefaultSrc');

  Check(
    CSP.Init.FontSrc.Any.CSP.Policy =
    'font-src *',
    'CSP: FontSrc');

  Check(
    CSP.Init.FrameSrc.Any.CSP.Policy =
    'frame-src *',
    'CSP: FrameSrc');

  Check(
    CSP.Init.ImgSrc.Any.CSP.Policy =
    'img-src *',
    'CSP: ImgSrc');

  Check(
    CSP.Init.ManifestSrc.Any.CSP.Policy =
    'manifest-src *',
    'CSP: ManifestSrc');

  Check(
    CSP.Init.MediaSrc.Any.CSP.Policy =
    'media-src *',
    'CSP: MediaSrc');

  Check(
    CSP.Init.PrefetchSrc.Any.CSP.Policy =
    'prefetch-src *',
    'CSP: PrefetchSrc');

  Check(
    CSP.Init.ObjectSrc.Any.CSP.Policy =
    'object-src *',
    'CSP: ObjectSrc');

  Check(
    CSP.Init.ScriptSrc.Any.CSP.Policy =
    'script-src *',
    'CSP: ScriptSrc');

  Check(
    CSP.Init.ScriptSrcElem.Any.CSP.Policy =
    'script-src-elem *',
    'CSP: ScriptSrcElem');

  Check(
    CSP.Init.ScriptSrcAttr.Any.CSP.Policy =
    'script-src-attr *',
    'CSP: ScriptSrcAttr');

  Check(
    CSP.Init.StyleSrc.Any.CSP.Policy =
    'style-src *',
    'CSP: StyleSrc');

  Check(
    CSP.Init.StyleSrcElem.Any.CSP.Policy =
    'style-src-elem *',
    'CSP: StyleSrcElem');

  Check(
    CSP.Init.StyleSrcAttr.Any.CSP.Policy =
    'style-src-attr *',
    'CSP: StyleSrcAttr');

  Check(
    CSP.Init.WorkerSrc.Any.CSP.Policy =
    'worker-src *',
    'CSP: WorkerSrc');

  Check(
    CSP.Init.BaseURI.Any.CSP.Policy =
    'base-uri *',
    'CSP: BaseURI');

  PluginTypes := CSP.Init.PluginTypes;
  PluginTypes.MediaType('application', 'json');
  Check(CSP.Policy = 'plugin-types application/json', 'CSP: PluginTypes');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowPopups;
  Check(CSP.Policy = 'sandbox allow-popups', 'CSP: Sandbox');

  Check(
    CSP.Init.FormAction.Any.CSP.Policy =
    'form-action *',
    'CSP: FormAction');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.WithSelf;
  Check(CSP.Policy = 'frame-ancestors ''self''', 'CSP: FrameAncestors');

  Check(
    CSP.Init.NavigateTo.Any.CSP.Policy =
    'navigate-to *',
    'CSP: NavigateTo');

  Check(
    CSP.Init.ReportTo('/csp-report').Policy =
    'report-to /csp-report',
    'CSP: ReportTo');

  Check(
    CSP.Init.ReportTo('/csp-report').ReportTo('/csp-report-2').Policy =
    'report-to /csp-report-2',
    'CSP: ReportTo single token');

  Check(
    CSP.Init.BlockAllMixedContent.Policy =
    'block-all-mixed-content',
    'CSP: BlockAllMixedContent');

  Check(
    CSP.Init.UpgradeInsecureRequests.Policy =
    'upgrade-insecure-requests',
    'CSP: UpgradeInsecureRequests');

  Check(
    CSP.Init.RequireSRIFor(csp3SRIScript).Policy =
    'require-sri-for script',
    'CSP: RequireSRIFor script');
end;

procedure TCSP3Should.SupportExtensions;
var
  CSP: TCSP3;
begin
  Check(
    CSP.Init.BlockAllMixedContent.Policy =
    'block-all-mixed-content',
    'CSP: BlockAllMixedContent');

  Check(
    CSP.Init.UpgradeInsecureRequests.Policy =
    'upgrade-insecure-requests',
    'CSP: UpgradeInsecureRequests');

  Check(
    CSP.Init.RequireSRIFor(csp3SRIScript).Policy =
    'require-sri-for script',
    'CSP: RequireSRIFor script');

  Check(
    CSP.Init.RequireSRIFor(csp3SRIStyle).Policy =
    'require-sri-for style',
    'CSP: RequireSRIFor style');

  Check(
    CSP.Init.RequireSRIFor(csp3SRIScriptStyle).Policy =
    'require-sri-for script style',
    'CSP: RequireSRIFor script style');
end;

procedure TCSP3Should.SupportFrameAncestors;
var
  CSP: TCSP3;
  FrameAncestors: TCSP3FrameAncestors;
begin
  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Add('x');
  Check(CSP.Policy = 'frame-ancestors x', 'FrameAncestors: Add');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Add('x').Add('y').Add('z');
  Check(CSP.Policy = 'frame-ancestors x y z', 'FrameAncestors: Several values');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.None;
  Check(CSP.Policy = 'frame-ancestors ''none''', 'FrameAncestors: None');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Scheme('https').None;
  Check(CSP.Policy = 'frame-ancestors ''none''',
    'FrameAncestors: None on non-empty list');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Scheme('https');
  Check(CSP.Policy = 'frame-ancestors https:', 'FrameAncestors: Scheme');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('', 'example.com', '', '');
  Check(CSP.Policy = 'frame-ancestors example.com', 'FrameAncestors: Host');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('https', 'example.com', '', '');
  Check(CSP.Policy = 'frame-ancestors https://example.com',
    'FrameAncestors: Host, Scheme');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('', 'example.com', '8080', '');
  Check(CSP.Policy = 'frame-ancestors example.com:8080',
    'FrameAncestors: Host, Port');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('', 'example.com', '', '/now');
  Check(CSP.Policy = 'frame-ancestors example.com/now',
    'FrameAncestors: Host, Path');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('', 'example.com', '8080', '/now');
  Check(CSP.Policy = 'frame-ancestors example.com:8080/now',
    'FrameAncestors: Host, Port, Path');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('https', 'example.com', '8080', '/now');
  Check(CSP.Policy = 'frame-ancestors https://example.com:8080/now',
    'FrameAncestors: Scheme, Host, Port, Path');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.Host('https://example.com:8080/now');
  Check(CSP.Policy = 'frame-ancestors https://example.com:8080/now',
    'FrameAncestors: Raw Host');

  FrameAncestors := CSP.Init.FrameAncestors;
  FrameAncestors.WithSelf;
  Check(CSP.Policy = 'frame-ancestors ''self''',
    'FrameAncestors: WithSelf');
end;

procedure TCSP3Should.SupportHTTPHeaders;
var
  CSP: TCSP3;
begin
  Check(
    CSP.Init.DefaultSrc.WithSelf.CSP.HTTPHeader =
    'Content-Security-Policy: default-src ''self'''#$D#$A,
    'HTTPHeaders: CSP');

  Check(
    CSP.Init.DefaultSrc.WithSelf.CSP.HTTPHeaderReportOnly =
    'Content-Security-Policy-Report-Only: default-src ''self'''#$D#$A,
    'HTTPHeaders: CSP Reports Only');
end;

procedure TCSP3Should.SupportMediaTypeList;
var
  CSP: TCSP3;
  PluginTypes: TCSP3MediaTypeList;
begin
  PluginTypes := CSP.Init.PluginTypes;
  PluginTypes.Add('x');
  Check(CSP.Policy = 'plugin-types x', 'MediaTypeList: Add');

  PluginTypes := CSP.Init.PluginTypes;
  PluginTypes.Add('x').Add('y').Add('z');
  Check(CSP.Policy = 'plugin-types x y z', 'MediaTypeList: Several values');

  PluginTypes := CSP.Init.PluginTypes;
  PluginTypes.MediaType('application', 'json');
  Check(CSP.Policy = 'plugin-types application/json',
    'MediaTypeList: MediaType');
end;

procedure TCSP3Should.SupportSandboxTokens;
var
  CSP: TCSP3;
  Sandbox: TCSP3SandboxTokens;
begin
  Sandbox := CSP.Init.Sandbox;
  Sandbox.Add('x');
  Check(CSP.Policy = 'sandbox x', 'SandboxTokens: Add');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.Add('x').Add('y').Add('z');
  Check(CSP.Policy = 'sandbox x y z', 'SandboxTokens: Several values');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.Empty;
  Check(CSP.Policy = 'sandbox', 'SandboxTokens: Empty');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.Add('x').Empty;
  Check(CSP.Policy = 'sandbox', 'SandboxTokens: Empty on non-empty list');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowPopups;
  Check(CSP.Policy = 'sandbox allow-popups', 'SandboxTokens: AllowPopups');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowTopNavigation;
  Check(CSP.Policy = 'sandbox allow-top-navigtion',
    'SandboxTokens: AllowTopNavigation');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowTopNavigationByUserActivation;
  Check(CSP.Policy = 'sandbox allow-top-navigation-by-user-activation',
    'SandboxTokens: AllowTopNavigationByUserActivation');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowSameOrigin;
  Check(CSP.Policy = 'sandbox allow-same-origin',
    'SandboxTokens: AllowSameOrigin');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowForms;
  Check(CSP.Policy = 'sandbox allow-forms', 'SandboxTokens: AllowForms');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowPointerLock;
  Check(CSP.Policy = 'sandbox allow-pointer-lock',
    'SandboxTokens: AllowPointerLock');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowScripts;
  Check(CSP.Policy = 'sandbox allow-scripts', 'SandboxTokens: AllowScripts');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowPopupsToEscapeSandbox;
  Check(CSP.Policy = 'sandbox allow-popups-to-escape-sandbox',
    'SandboxTokens: AllowPopupsToEscapeSandbox');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowModals;
  Check(CSP.Policy = 'sandbox allow-modals', 'SandboxTokens: AllowModals');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowOrientationLock;
  Check(CSP.Policy = 'sandbox allow-orientation-lock',
    'SandboxTokens: AllowOrientationLock');

  Sandbox := CSP.Init.Sandbox;
  Sandbox.AllowPresentation;
  Check(CSP.Policy = 'sandbox allow-presentation',
    'SandboxTokens: AllowPresentation');
end;

procedure TCSP3Should.SupportSourceList;
var
  CSP: TCSP3;
  Value: RawByteString;
  Nonce, Hash: SockString;
  Hash256: THash256;
  Hash384: THash384;
  Hash512: THash512;
begin
  Check(
    CSP.Init.DefaultSrc.Add('x').CSP.Policy =
    'default-src x',
    'SourceList: Add');

  Check(
    CSP.Init.DefaultSrc.Add('x').Add('y').Add('z').CSP.Policy =
    'default-src x y z',
    'SourceList: Several values');

  Check(
    CSP.Init.DefaultSrc.None.CSP.Policy =
    'default-src ''none''',
    'SourceList: None');

  Check(
    CSP.Init.DefaultSrc.Any.None.CSP.Policy =
    'default-src ''none''',
    'SourceList: None on non-empty list');

  Check(
    CSP.Init.DefaultSrc.Null.CSP.Policy =
    'default-src null',
    'SourceList: Null');

  Check(
    CSP.Init.DefaultSrc.Any.CSP.Policy =
    'default-src *',
    'SourceList: Any');

  Check(
    CSP.Init.DefaultSrc.Scheme('https').CSP.Policy =
    'default-src https:',
    'SourceList: Scheme');

  Check(
    CSP.Init.DefaultSrc.Host('', 'example.com', '', '').CSP.Policy =
    'default-src example.com',
    'SourceList: Host');

  Check(
    CSP.Init.DefaultSrc.Host('https', 'example.com', '', '').CSP.Policy =
    'default-src https://example.com',
    'SourceList: Host, Scheme');

  Check(
    CSP.Init.DefaultSrc.Host('', 'example.com', '8080', '').CSP.Policy =
    'default-src example.com:8080',
    'SourceList: Host, Port');

  Check(
    CSP.Init.DefaultSrc.Host('', 'example.com', '', '/now').CSP.Policy =
    'default-src example.com/now',
    'SourceList: Host, Path');

  Check(
    CSP.Init.DefaultSrc.Host('', 'example.com', '8080', '/now').CSP.Policy =
    'default-src example.com:8080/now',
    'SourceList: Host, Port, Path');

  Check(
    CSP.Init.DefaultSrc.Host('https', 'example.com', '8080', '/now').
      CSP.Policy =
    'default-src https://example.com:8080/now',
    'SourceList: Scheme, Host, Port, Path');

  Check(
    CSP.Init.DefaultSrc.Host('https://example.com:8080/now').CSP.Policy =
    'default-src https://example.com:8080/now',
    'SourceList: Raw Host');

  Check(
    CSP.Init.DefaultSrc.WithSelf.CSP.Policy =
    'default-src ''self''',
    'SourceList: WithSelf');

  Check(
    CSP.Init.DefaultSrc.UnsafeInline.CSP.Policy =
    'default-src ''unsafe-inline''',
    'SourceList: UnsafeInline');

  Check(
    CSP.Init.DefaultSrc.UnsafeEval.CSP.Policy =
    'default-src ''unsafe-eval''',
    'SourceList: UnsafeEval');

  Check(
    CSP.Init.DefaultSrc.StrictDynamic.CSP.Policy =
    'default-src ''strict-dynamic''',
    'SourceList: StrictDynamic');

  Check(
    CSP.Init.DefaultSrc.UnsafeHashes.CSP.Policy =
    'default-src ''unsafe-hashes''',
    'SourceList: UnsafeHashes');

  Check(
    CSP.Init.DefaultSrc.ReportSample.CSP.Policy =
    'default-src ''report-sample''',
    'SourceList: ReportSample');

  Check(
    CSP.Init.DefaultSrc.UnsafeAllowRedirects.CSP.Policy =
    'default-src ''unsafe-allow-redirects''',
    'SourceList: UnsafeAllowRedirects');

  Value := CSP.Init.DefaultSrc.NonceLen(Nonce).CSP.Policy;
  Check(
    Copy(Value, 1, Length('default-src ''nonce-')) = 'default-src ''nonce-',
    'SourceList: Nonce prefix');
  Delete(Value, 1, Length('default-src ''nonce-'));
  Check(
    Copy(Value, Length(Value), 1) = '''',
    'SourceList: Nonce postfix');
  Delete(Value, Length(Value), 1);
  Check(Value = Nonce, 'SourceList: Nonce');

  Value := CSP.Init.DefaultSrc.NonceLen(Nonce, 128).CSP.Policy;
  Delete(Value, 1, Length('default-src ''nonce-'));
  Delete(Value, Length(Value), 1);
  Check(Length(Base64ToBin(Value)) = 128 shr 3,
    'SourceList: Nonce with custom length');

  CSP.Init.DefaultSrc.NonceLen(Nonce, 4096, True).CSP.Policy;
  Check((SynCommons.PosEx('-', Nonce) > 0) and
    (SynCommons.PosEx('_', Nonce) > 0),
      'SourceList: Nonce in Base64url encoding');

  Value := CSP.Init.DefaultSrc.Nonce(RawByteString(#$FF'test-nonce')).
    CSP.Policy;
  Check(
    Copy(Value, 1, Length('default-src ''nonce-')) = 'default-src ''nonce-',
    'SourceList: Nonce by value prefix');
  Delete(Value, 1, Length('default-src ''nonce-'));
  Check(
    Copy(Value, Length(Value), 1) = '''',
    'SourceList: Nonce by value postfix');
  Delete(Value, Length(Value), 1);
  Check(Base64ToBin(Value) = #$FF'test-nonce', 'SourceList: Nonce by value');

  Value := CSP.Init.DefaultSrc.Nonce(RawByteString(#$FF'test-nonce'), True).
    CSP.Policy;
  Delete(Value, 1, Length('default-src ''nonce-'));
  Delete(Value, Length(Value), 1);
  Check(Base64uriToBin(Value) = #$FF'test-nonce','SourceList: Base64url Nonce');

  Check(
    CSP.Init.DefaultSrc.Nonce64('test').CSP.Policy =
    'default-src ''nonce-test''',
    'SourceList: Raw Nonce');

  Check(
    CSP.Init.DefaultSrc.SHA256('alert(''Hello, world.'');', @Hash).CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=']),
    'SourceList: SHA256');
  Check(Hash = 'qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=',
    'SourceList: SHA256 Hash');

  Check(
    CSP.Init.DefaultSrc.SHA256('alert(''Hello, world.'');', @Hash, True).
      CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG-HiZ1guq6ZZDob_Tng']),
    'SourceList: SHA256 in Base64url encoding');
  Check(Hash = 'qznLcsROx4GACP2dm0UCKCzCG-HiZ1guq6ZZDob_Tng',
    'SourceList: SHA256 Hash in Base64url encoding');

  Value := HexToBin(
    'ab39cb72c44ec7818008fd9d9b450228' +
    '2cc21be1e267582eaba6590e86ff4e78');
  Move(Value[1], Hash256, SizeOf(THash256));
  Check(
    CSP.Init.DefaultSrc.SHA256Hash(Hash256).CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=']),
    'SourceList: SHA256Hash from THash256');

  Value := HexToBin(
    'ab39cb72c44ec7818008fd9d9b450228' +
    '2cc21be1e267582eaba6590e86ff4e78');
  Move(Value[1], Hash256, SizeOf(THash256));
  Check(
    CSP.Init.DefaultSrc.SHA256Hash(Hash256, True).CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG-HiZ1guq6ZZDob_Tng']),
    'SourceList: SHA256Hash from THash256 in Base64url encoding');

  Value := HexToBin(
    'ab39cb72c44ec7818008fd9d9b450228' +
    '2cc21be1e267582eaba6590e86ff4e78');
  Check(
    CSP.Init.DefaultSrc.SHA256Hash(Value).CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=']),
    'SourceList: SHA256Hash from RawByteString');

  Value := HexToBin(
    'ab39cb72c44ec7818008fd9d9b450228' +
    '2cc21be1e267582eaba6590e86ff4e78');
  Check(
    CSP.Init.DefaultSrc.SHA256Hash(Value, True).CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG-HiZ1guq6ZZDob_Tng']),
    'SourceList: SHA256Hash from RawByteString in Base64url encoding');

  Check(
    CSP.Init.DefaultSrc.SHA256Hash64(
      'qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=').CSP.Policy =
    FormatUTF8('default-src ''sha256-%''',
      ['qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=']),
    'SourceList: SHA256Hash64');

  Check(
    CSP.Init.DefaultSrc.SHA384('alert(''Hello, world.'');', @Hash).CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO']),
    'SourceList: SHA384');
  Check(Hash =
    'H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO',
    'SourceList: SHA384 Hash');

  Check(
    CSP.Init.DefaultSrc.SHA384('alert(''Hello, world.'');', @Hash, True).
      CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t-eX6xO']),
    'SourceList: SHA384');
  Check(Hash =
    'H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t-eX6xO',
    'SourceList: SHA384 Hash in Base64url encoding');

  Value := HexToBin(
    '1fc05187c8f8f0ef6861ab5fbb9019ceae80f5120d8593b9'+
    '1f5e9d4199e02bb4fad9e9bc314b7514b9b9dadf9e5fac4e');
  Move(Value[1], Hash384, SizeOf(THash384));
  Check(
    CSP.Init.DefaultSrc.SHA384Hash(Hash384).CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO']),
    'SourceList: SHA384Hash from THash384');

  Value := HexToBin(
    '1fc05187c8f8f0ef6861ab5fbb9019ceae80f5120d8593b9'+
    '1f5e9d4199e02bb4fad9e9bc314b7514b9b9dadf9e5fac4e');
  Move(Value[1], Hash384, SizeOf(THash384));
  Check(
    CSP.Init.DefaultSrc.SHA384Hash(Hash384, True).CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t-eX6xO']),
    'SourceList: SHA384Hash from THash384 in Base64url encoding');

  Value := HexToBin(
    '1fc05187c8f8f0ef6861ab5fbb9019ceae80f5120d8593b9'+
    '1f5e9d4199e02bb4fad9e9bc314b7514b9b9dadf9e5fac4e');
  Check(
    CSP.Init.DefaultSrc.SHA384Hash(Value).CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO']),
    'SourceList: SHA384Hash from RawByteString');

  Value := HexToBin(
    '1fc05187c8f8f0ef6861ab5fbb9019ceae80f5120d8593b9'+
    '1f5e9d4199e02bb4fad9e9bc314b7514b9b9dadf9e5fac4e');
  Check(
    CSP.Init.DefaultSrc.SHA384Hash(Value, True).CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t-eX6xO']),
    'SourceList: SHA384Hash from RawByteString in Base64url encoding');

  Check(
    CSP.Init.DefaultSrc.SHA384Hash64(
      'H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO')
      .CSP.Policy =
    FormatUTF8('default-src ''sha384-%''',
      ['H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO']),
    'SourceList: SHA384Hash64');

  Check(
    CSP.Init.DefaultSrc.SHA512('alert(''Hello, world.'');', @Hash).CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==']),
    'SourceList: SHA512');
  Check(Hash =
    'Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
    '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==',
    'SourceList: SHA512 Hash');

  Check(
    CSP.Init.DefaultSrc.SHA512('alert(''Hello, world.'');', @Hash, True).
      CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9_A0EzCinRE7Af1ofPrw']),
    'SourceList: SHA512');
  Check(Hash =
    'Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
    '3WoNr3bjZSAHeOsHrbV1Fu9_A0EzCinRE7Af1ofPrw',
    'SourceList: SHA512 Hash in Base64url encoding');

  Value := HexToBin(
    '4366c54ce84400b90df213a6b3614a4c32f2edeba03f6cc56754fc2c2bd7e361' +
    '69dd6a0daf76e365200778eb07adb57516ef7f0341330a29d113b01fd687cfaf');
  Move(Value[1], Hash512, SizeOf(THash512));
  Check(
    CSP.Init.DefaultSrc.SHA512Hash(Hash512).CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==']),
    'SourceList: SHA512Hash from THash512');

  Value := HexToBin(
    '4366c54ce84400b90df213a6b3614a4c32f2edeba03f6cc56754fc2c2bd7e361' +
    '69dd6a0daf76e365200778eb07adb57516ef7f0341330a29d113b01fd687cfaf');
  Move(Value[1], Hash512, SizeOf(THash512));
  Check(
    CSP.Init.DefaultSrc.SHA512Hash(Hash512, True).CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9_A0EzCinRE7Af1ofPrw']),
    'SourceList: SHA512Hash from THash512 in Base64url encoding');

  Value := HexToBin(
    '4366c54ce84400b90df213a6b3614a4c32f2edeba03f6cc56754fc2c2bd7e361' +
    '69dd6a0daf76e365200778eb07adb57516ef7f0341330a29d113b01fd687cfaf');
  Check(
    CSP.Init.DefaultSrc.SHA512Hash(Value).CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==']),
    'SourceList: SHA512Hash from RawByteString');

  Value := HexToBin(
    '4366c54ce84400b90df213a6b3614a4c32f2edeba03f6cc56754fc2c2bd7e361' +
    '69dd6a0daf76e365200778eb07adb57516ef7f0341330a29d113b01fd687cfaf');
  Check(
    CSP.Init.DefaultSrc.SHA512Hash(Value, True).CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9_A0EzCinRE7Af1ofPrw']),
    'SourceList: SHA512Hash from RawByteString in Base64url encoding');

  Check(
    CSP.Init.DefaultSrc.SHA512Hash64(
      'Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
      '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==').CSP.Policy =
    FormatUTF8('default-src ''sha512-%''',
      ['Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp' +
       '3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw==']),
    'SourceList: SHA512Hash64');
end;

{ TSQLRestServerURI }

procedure TSQLRestServerURI.URI(var Call: TSQLRestURIParams);
begin
  if CustomStatus > 0 then
  begin
    Call.OutHead := 'Content-Type: text/html; charset=utf-8';
    Call.OutBody := '';
    Call.OutStatus := CustomStatus;
  end else
    inherited;
end;


{ TBoilerplateHTTPServerSteps }

procedure TBoilerplateHTTPServerSteps.GivenOptions(
  const AOptions: TBoilerplateOptions);
begin
  inherited Options := AOptions;
end;

procedure TBoilerplateHTTPServerSteps.GivenOutHeader(const aName,
  aValue: RawUTF8);
begin
  FContext.OutCustomHeaders := FContext.OutCustomHeaders +
    FormatUTF8('%: %', [aName, aValue]);
end;

procedure TBoilerplateHTTPServerSteps.GivenReferrerPolicy(const Value: RawUTF8);
begin
  ReferrerPolicy := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenServeExactCaseURL(
  const Value: Boolean);
begin
  RedirectServerRootUriForExactCase := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenStaticFile(const URL: SockString);
begin
  FContext.URL := URL;
  FContext.Method := 'GET';
  FContext.Result := inherited Request(FContext);
end;

procedure TBoilerplateHTTPServerSteps.GivenStaticRoot(const Value: TFileName);
begin
  StaticRoot := ExtractFilePath(ParamStr(0)) + Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenStrictSSL(const Value: TStrictSSL);
begin
  StrictSSL := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenWWWRewrite(const Value: TWWWRewrite);
begin
  WWWRewrite := Value;
end;

procedure TBoilerplateHTTPServerSteps.RemoveDir(const FileName: string);
begin
  SysUtils.RemoveDir(NormalizeFileName(FullFileName(FileName)));
end;

procedure TBoilerplateHTTPServerSteps.GivenClearServer;
begin
  FContext.Init;
  inherited Init;
end;

procedure TBoilerplateHTTPServerSteps.GivenContentSecurityPolicy(
  const Value: SockString);
begin
  ContentSecurityPolicy := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenContentSecurityPolicyReportOnly(
  const Value: SockString);
begin
  ContentSecurityPolicyReportOnly := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenCustomStatus(const Status: Cardinal);
begin
  TSQLRestServerURI(FServer).CustomStatus := Status;
end;

procedure TBoilerplateHTTPServerSteps.GivenDNSPrefetchControl(
  const Value: TDNSPrefetchControl);
begin
  DNSPrefetchControl := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenDNSPrefetchControlContentTypes(
  const Value: SockString);
begin
  DNSPrefetchControlContentTypes := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenExternalAsset(
  const AssetType: THTTPAssetType; const APath: RawUTF8;
  const ATimestamp: TUnixTime; const AContentType: RawUTF8;
  const AGZipExists, ABrotliExists: Boolean;
  const AContent, AGZipContent, ABrotliContent: RawByteString;
  const AContentHash, AGZipHash, ABrotliHash: Cardinal);
begin
  FExternalAssetType := AssetType;
  with FExternalAsset do
  begin
    Path := APath;
    Timestamp := ATimestamp;
    Content := AContent;
    ContentHash := AContentHash;
    ContentType := AContentType;
    GZipExists := AGZipExists;
    GZipContent := AGZipContent;
    GZipHash := AGZipHash;
    BrotliExists := ABrotliExists;
    BrotliContent := ABrotliContent;
    BrotliHash := ABrotliHash;
  end;
end;

procedure TBoilerplateHTTPServerSteps.GivenModifiedFile(
  const FileName: TFileName;
  const KeepTimeStamp, KeepSize: Boolean);
const
  ADD_BYTE: array[Boolean] of Integer = (0, 1);
var
  LFileName: string;
  Modified: TUnixTime;
  Size: Int64;
begin
  LFileName := NormalizeFileName(FileName);
  GetFileInfo(LFileName, @Modified, @Size);
  FileFromString(
    ToUTF8(StringOfChar(#0, Size + ADD_BYTE[not KeepSize])), LFileName, True);
  if KeepTimeStamp then
    SetFileTime(LFileName, Modified)
  else
    SetFileTime(LFileName, UnixTimeUTC);
end;

procedure TBoilerplateHTTPServerSteps.GivenExpires(const Value: RawUTF8);
begin
  Expires := Value;
end;

function TBoilerplateHTTPServerSteps.GetExternalAsset(const Path: RawUTF8;
  var AssetType: THTTPAssetType; var Asset: TAsset): Boolean;
begin
  Result := (Path <> '') and (Path = FExternalAsset.Path);
  if Result then
  begin
    Asset.Assign(FExternalAsset);
    AssetType := FExternalAssetType;
  end;
end;

function TBoilerplateHTTPServerSteps.GetFileContent(
  const FileName: TFileName): RawByteString;
var
  LFileName: string;
begin
  LFileName := NormalizeFileName(FullFileName(FileName));
  FTestCase.CheckUTF8(FileExists(LFileName),
    'File not found ''%''', [LFileName]);
  Result := StringFromFile(LFileName);
end;

procedure TBoilerplateHTTPServerSteps.GivenAssets(const Name: string);
begin
  inherited LoadFromResource(Name);
end;

constructor TBoilerplateHTTPServerSteps.Create(const TestCase: TSynTestCase;
  const Auth: Boolean; AApplication: IBoilerplateApplication; AUseSSL: Boolean);
const
  DEFAULT_SOCKET_PORT = '127.0.0.1:9000';
  SERVER_SECURITY: array[Boolean] of TSQLHTTPServerSecurity = (secNone, secSSL);
begin
  RemoteIPLocalHostAsVoidInServers := False;
  FTestCase := TestCase;
  FModel := TSQLModel.Create([TSQLRecord]);
  FServer := TSQLRestServerURI.Create(FModel, Auth);
  FApplication := AApplication;
  if FApplication = nil then
  begin
    FApplication := TBoilerplateApplication.Create;
    TBoilerplateApplication(ObjectFromInterface(FApplication)).Start(
      FServer, FullFileName('Views'));
  end else
    if ObjectFromInterface(FApplication).ClassType = TBoilerplateApplication then
      TBoilerplateApplication(ObjectFromInterface(FApplication)).Start(
        FServer, FullFileName('Views'))
    else if ObjectFromInterface(FApplication).ClassType = T404Application then
      T404Application(ObjectFromInterface(FApplication)).Start(
        FServer, FullFileName('Views'))
    else
      TMVCApplication(ObjectFromInterface(FApplication)).Start(
        FServer, TypeInfo(IBoilerplateApplication));
  FContext := THttpServerRequestStub.Create(nil, 0, nil);
  inherited Create(DEFAULT_SOCKET_PORT, FServer, '+', useHttpSocket,
    @FServerAccessRights, 2, SERVER_SECURITY[AUseSSL]);
  DomainHostRedirect('127.0.0.1', 'root');
  DomainHostRedirect('localhost', 'root');
  OnGetAsset := GetExternalAsset;
end;

procedure TBoilerplateHTTPServerSteps.ThenRequestResultIs(const Value: Cardinal);
begin
  FTestCase.CheckUTF8(FContext.Result = Value,
    'Request result expected=%, actual=%', [Value, FContext.Result]);
end;

procedure TBoilerplateHTTPServerSteps.DeleteFile(const FileName: string);
begin
  SysUtils.DeleteFile(NormalizeFileName(FullFileName(FileName)));
end;

destructor TBoilerplateHTTPServerSteps.Destroy;
begin
  THTTPServer(FHttpServer).ServerKeepAliveTimeOut := 0;
  THTTPServer(FHttpServer).Sock.KeepAlive := 10;
  THTTPServer(FHttpServer).Sock.SendTimeout := 10;
  THTTPServer(FHttpServer).Sock.ReceiveTimeout := 10;
  inherited Destroy;
  FContext.Free;
  FApplication := nil;
  FServer.Free;
  FModel.Free;
end;

function TBoilerplateHTTPServerSteps.FullFileName(
  const FileName: string): string;
begin
  Result := ExtractFilePath(ParamStr(0)) + FileName;
end;

procedure TBoilerplateHTTPServerSteps.ThenApp404Called;
begin
  FTestCase.Check(
    T404Application(ObjectFromInterface(FApplication)).Is404Called,
    'App404 not called');
end;

procedure TBoilerplateHTTPServerSteps.ThenFileContentIsEqualToAsset(
  const FileName: TFileName; const Path: RawUTF8);
var
  Asset: PAsset;
begin
  Asset := FAssets.Find(Path);
  FTestCase.CheckUTF8(Asset <> nil, 'Asset not found ''%''', [Path]);
  FTestCase.CheckUTF8(GetFileContent(FileName) = Asset.Content,
    'Unexpected not equal content between file ''%'' and asset ''%''',
    [FileName, Path]);
end;

procedure TBoilerplateHTTPServerSteps.ThenFileContentIsNotEqualToAsset(
  const FileName: TFileName; const Path: RawUTF8);
var
  Asset: PAsset;
begin
  Asset := FAssets.Find(Path);
  FTestCase.CheckUTF8(Asset <> nil, 'Asset not found ''%''', [Path]);
  FTestCase.CheckUTF8(GetFileContent(FileName) <> Asset.Content,
    'Unexpected equal content between file ''%'' and asset ''%''',
    [FileName, Path]);
end;

procedure TBoilerplateHTTPServerSteps.ThenFileTimestampAndSizeAreEqualToAsset(
  const FileName: TFileName; const Path: RawUTF8);
var
  Asset: PAsset;
  Modified: TUnixTime;
  Size: Int64;
begin
  Asset := FAssets.Find(Path);
  FTestCase.CheckUTF8(Asset <> nil, 'Asset not found ''%''', [Path]);
  FTestCase.CheckUTF8(
    GetFileInfo(NormalizeFileName(FullFileName(FileName)), @Modified, @Size),
    'GetFileInfo failed ''%''', [FileName]);
  FTestCase.CheckUTF8(Modified = Asset.Timestamp,
    'File modified are not equal to asset file=%, asset=%', [
      FormatDateTime('YYYY-MM-DD HH:NN:SS.ZZZ', Modified),
      FormatDateTime('YYYY-MM-DD HH:NN:SS.ZZZ', Asset.Timestamp)]);
  FTestCase.CheckUTF8(Size = Length(Asset.Content),
    'File size are not equal to asset file=%, asset=%',
      [Size, Length(Asset.Content)]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentEqualsFile(
  const FileName: TFileName);
begin
  FTestCase.CheckUTF8(FContext.OutContent = GetFileContent(FileName),
    'File content mismatch ''%'' actual=''%''expected=''%''',
      [FileName, FContext.OutContent, GetFileContent(FileName)]);
end;

procedure TBoilerplateHTTPServerSteps.GivenInHeader(
  const aName, aValue: RawUTF8);
begin
  FContext.InHeaders := FContext.InHeaders +
    FormatUTF8('%: %', [aName, aValue]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutHeaderValueIs(
  const aName, aValue: RawUTF8);
var
  NameUp: SockString;
  Value: RawUTF8;
begin
  NameUp := SockString(SynCommons.UpperCase(aName) + ': ');
  Value := FindIniNameValue(Pointer(FContext.OutCustomHeaders),
    Pointer(NameUp));
  FTestCase.CheckUTF8(Value = aValue,
    'OutHeader ''%'' expected=''%'', actual=''%''', [aName, aValue, Value]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIsStaticFile(
  const StaticFileName, FileName: TFileName);
begin
  FTestCase.CheckUTF8(GetFileContent(StaticFileName) = GetFileContent(FileName),
    'File content mismatch ''%''', [FileName]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIs(
  const Value: RawByteString);
begin
  FTestCase.CheckUTF8(FContext.OutContent = Value,
    'OutContent expected=''%'', actual=''%''', [Value, FContext.OutContent]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIsEmpty;
begin
  FTestCase.CheckUTF8(FContext.OutContent = '',
    'HTTP Response content is not empty ''%''', [FContext.OutContent]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIsStatic(
  const FileName: TFileName);
var
  LFileName: string;
begin
  FTestCase.CheckUTF8(FContext.OutContentType = HTTP_RESP_STATICFILE,
    'OutContentIsStatic expected=''%'', actual=''%''',
    [HTTP_RESP_STATICFILE, FContext.OutContentType]);

  LFileName := NormalizeFileName(FileName);
  FTestCase.CheckUTF8(TFileName(FContext.OutContent) = LFileName,
    'OutContentIsStatic expected=''%'', actual=''%''',
    [LFileName, FContext.OutContent]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentTypeIs(
  const Value: RawUTF8);
begin
  FTestCase.CheckUTF8(FContext.OutContentType = Value,
    'OutContentType expected=''%'', actual=''%''',
    [Value, FContext.OutContentType]);
end;

procedure TBoilerplateHTTPServerSteps.WhenRequest(const URL: SockString;
  const Host: SockString; const UseSSL: Boolean; const Method: SockString);
begin
  if URL <> '' then
    FContext.URL := URL;
  if Host <> '' then
    FContext.InHeaders :=
      FormatUTF8('%Host: %'#$D#$A, [FContext.InHeaders, Host]);
  FContext.Method := Method;
  FContext.UseSSL := UseSSL;
  FContext.Result := inherited Request(FContext);
end;

{ THttpServerRequestStub }

procedure THttpServerRequestStub.Init;
begin
  Prepare('', '', '', '', '', '', False);
  FOutCustomHeaders := '';
  FOutContentType := '';
  FOutContent := '';
  FResult := 0;
end;

{ TBoilerplateApplication }

procedure TBoilerplateApplication.Default(var Scope: Variant);
begin
  TDocVariant.NewFast(Scope);
  Scope.Content := 'CONTENT';
end;

procedure TBoilerplateApplication.Error(var Msg: RawUTF8; var Scope: Variant);
begin
  TDocVariant.NewFast(Scope);
  Scope.Content := 'CONTENT';
end;

procedure TBoilerplateApplication.Start(Server: TSQLRestServer;
  const ViewsFolder: TFileName);
begin
  inherited Start(Server, TypeInfo(IBoilerplateApplication));
  FMainRunner := TMVCRunOnRestServer.Create(Self, fRestServer, '',
    TMVCViewsMustache.Create(FFactory.InterfaceTypeInfo,
      GetMustacheParams(ViewsFolder), (FRestModel as TSQLRestServer).LogClass));
end;

procedure TBoilerplateApplication._404(
  const Dummy: Integer; out Scope: Variant);
begin
  TDocVariant.NewFast(Scope);
  Scope.Content := 'NOT FOUND';
end;

{ T404Application }

procedure T404Application.Default(var Scope: Variant);
begin
end;

procedure T404Application.Error(var Msg: RawUTF8; var Scope: Variant);
begin
end;

procedure T404Application.Start(Server: TSQLRestServer;
  const ViewsFolder: TFileName);
begin
  inherited Start(Server, TypeInfo(IBoilerplateApplication));
  FMainRunner := TMVCRunOnRestServer.Create(Self, fRestServer, '',
    TMVCViewsMustache.Create(FFactory.InterfaceTypeInfo,
      GetMustacheParams(ViewsFolder), (FRestModel as TSQLRestServer).LogClass));
end;

procedure T404Application._404(const Dummy: Integer; out Scope: Variant);
begin
  Is404Called := True;
end;

{ TBoilerplateFeatures }

procedure TBoilerplateFeatures.Scenarios;
begin
  AddCase(TBoilerplateHTTPServerShould);
  AddCase(TCSP2Should);
  AddCase(TCSP3Should);
end;

end.
