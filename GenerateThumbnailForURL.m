#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    NSError *error    = nil;
    id       pool     = [ [ NSAutoreleasePool alloc ] init ];
    id       textData = [ NSData dataWithContentsOfURL: (NSURL *)url
                                              options: NSMappedRead
                                                error: &error       ];
    id       textString ;
    id       textView ;
    id       clipView ;

    const char      *enc ;
    CFStringEncoding encoding  ;
    CGContextRef     cgContext ;
    NSRect           viewRect  ;
    NSSize           scaleBase ;
    float            scale     ;
    NSRect           dispRect  ;

    enc = guess_jp( [ textData bytes ], [ textData length ] ) ;
    if( enc != NULL )
    {
        encoding = CFStringConvertIANACharSetNameToEncoding( (CFStringRef)[ NSString stringWithCString: enc encoding:NSUTF8StringEncoding ] );

        textString = CFStringCreateFromExternalRepresentation( NULL, textData, encoding );
        [ textString autorelease ];

        viewRect = NSMakeRect( 0, 0, maxSize.width * 8.0,  maxSize.height * 8.0 );
        textView   = [ [ [ NSTextView alloc ] initWithFrame: viewRect ] autorelease ];
        [ textView insertText: textString ] ;
        [ textView sizeToFit ] ;
        viewRect = [ textView bounds ] ;

        scaleBase.width  = maxSize.width  / viewRect.size.width ;
        scaleBase.height = maxSize.height / viewRect.size.height ;

        scale =  scaleBase.width < scaleBase.height ? scaleBase.height : scaleBase.width ;
        dispRect = NSMakeRect( 0,0, maxSize.width / scale, maxSize.height / scale );


        cgContext = QLThumbnailRequestCreateContext( thumbnail, maxSize, false, NULL );

        if( cgContext ) 
        {
            NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped: YES ];
            if( context ) 
            {
                NSAffineTransform* xform = [NSAffineTransform transform];
                [xform translateXBy:0.0 yBy: maxSize.height ];
                [xform scaleXBy: scale  yBy:-scale  ];

                [NSGraphicsContext saveGraphicsState];
                [NSGraphicsContext setCurrentContext:context];
                [context saveGraphicsState];
                    [xform concat];
                    [textView drawRect: dispRect ];
                [context restoreGraphicsState];
                [NSGraphicsContext restoreGraphicsState];
            }
            QLThumbnailRequestFlushContext(thumbnail, cgContext);

            CFRelease(cgContext);
        }
    }
    [ pool release ];

    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}

