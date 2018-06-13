////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON REST CLIENT
//  Copyright 2015, Typhoon Rest Client Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

// Error Domain
static NSString *TyphoonRestClientErrors = @"TyphoonRestClientErrors";

// Error Codes
static NSInteger TyphoonRestClientErrorCodeValidation = 100;
static NSInteger TyphoonRestClientErrorCodeTransformation = 101;
static NSInteger TyphoonRestClientErrorCodeRequestUrlComposing = 103;
static NSInteger TyphoonRestClientErrorCodeRequestSerialization = 102;
static NSInteger TyphoonRestClientErrorCodeResponseSerialization = 104;
static NSInteger TyphoonRestClientErrorCodeBadResponse = 108;
static NSInteger TyphoonRestClientErrorCodeBadResponseCode = 105;
static NSInteger TyphoonRestClientErrorCodeBadResponseMime = 106;
static NSInteger TyphoonRestClientErrorCodeConnectionError = 107;

// UserInfo Dictionary Keys
static NSString *TyphoonRestClientErrorKeyFullDescription = @"TyphoonRestClientErrorKeyFullDescription";
static NSString *TyphoonRestClientErrorKeySchemaName = @"TyphoonRestClientErrorKeySchemaName";

static NSString *TyphoonRestClientErrorKeyResponseData = @"TyphoonRestClientErrorKeyResponseData";
static NSString *TyphoonRestClientErrorKeyResponse = @"TyphoonRestClientErrorKeyResponse";

static NSString *TyphoonRestClientErrorKeyOriginalError = @"TyphoonRestClientErrorKeyOriginalError";
static NSString *TyphoonRestClientErrorKeyStatusCode = @"TyphoonRestClientErrorKeyStatusCode";
