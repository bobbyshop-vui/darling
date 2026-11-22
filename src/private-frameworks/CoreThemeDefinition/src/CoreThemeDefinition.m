#import <Foundation/Foundation.h>

NSString *const CoreThemeDefinitionErrorDomain = @"CoreThemeDefinitionErrorDomain";

// Class identities imported by IBFoundation. Creating an asset catalog is unsupported.
@interface CoreThemeDocument : NSObject
@end

@implementation CoreThemeDocument

+ (instancetype)createConfiguredDocumentAtURL:(NSURL *)url error:(NSError **)error
{
    if (error != NULL) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                     code:NSFeatureUnsupportedError
                                 userInfo:@{NSLocalizedDescriptionKey: @"CoreThemeDefinition cannot create asset catalogs in Darling."}];
    }
    return nil;
}

@end

@interface TDDistiller : NSObject
@end

@implementation TDDistiller
@end

@interface TDNamedAssetImportInfo : NSObject
@end

@implementation TDNamedAssetImportInfo
@end

@interface TDThemeBitSource : NSObject
@end

@implementation TDThemeBitSource

- (NSURL *)fileURLWithDocument:(CoreThemeDocument *)document
{
    return nil;
}

@end
