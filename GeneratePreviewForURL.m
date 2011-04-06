#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>
#include "guess.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

static NSString *realTextBundlePath = "/System/Library/Frameworks/QuickLook.framework/Resources/Generators/Text.qlgenerator";

static NSBundle *realTextBundle     = nil ;


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSError *error    = nil;
    id       pool     = [ [ NSAutoreleasePool alloc ] init ];
    id       textData = [ NSData dataWithContentsOfURL: (NSURL *)url
                                              options: NSMappedRead
                                                error: &error       ];
    const char *enc ;
    CFStringEncoding encoding ;

    enc = guess_jp( [ textData bytes ], [ textData length ] ) ;
    if( enc != NULL )
    {
        encoding = CFStringConvertIANACharSetNameToEncoding( [ NSString stringWithCString: enc ] );

        if( encoding == CFStringGetSystemEncoding() )
        {
            QLPreviewRequestSetDataRepresentation( preview,  textData, kUTTypePlainText, NULL );
        }
        else 
        {
            id   textString, sjisData ;

            textString = CFStringCreateFromExternalRepresentation( NULL, textData, encoding );
            [ textString autorelease ];
 
            sjisData = [ textString dataUsingEncoding: [NSString defaultCStringEncoding ] ]; 
            QLPreviewRequestSetDataRepresentation( preview,  sjisData, kUTTypePlainText, NULL );
        }

    }
    [ pool release ];

    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
