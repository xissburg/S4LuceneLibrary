#import "AppDelegate.h"
#import "S4FileUtilities.h"
#import "S4CommonDefines.h"




static NSString *FIELD_TEXT = @"T";
static NSString *FIELD_PATH = @"P";

@implementation AppDelegate

@synthesize window;
@synthesize searchBar;
@synthesize resultField;



- (void)fillDirectory: (LCFSDirectory *)rd
{
    LCSimpleAnalyzer *analyzer = [[LCSimpleAnalyzer alloc] init];
    LCIndexWriter *writer = [[LCIndexWriter alloc] initWithDirectory: rd
                                                            analyzer: analyzer
                                                              create: YES];

    int i = 0;
    char buffer[40000];
    NSString *filePath = [[NSBundle mainBundle] pathForResource: @"data" ofType: @"txt"]; 
    
    S4DebugLog(@"opening %@", filePath);
    
    FILE *fh = fopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "r");
    
    if (fh) while(!feof(fh))
	{
        
        if (fgets(buffer, 40000, fh) == NULL)
		{
            S4DebugLog(@"no further line");
            break;
        }
        
        S4DebugLog(@"* %d", i);
        NSString *line = [[NSString alloc] initWithUTF8String: buffer];

        LCDocument *d = [[LCDocument alloc] init];

        LCField *f1 = [[LCField alloc] initWithName: FIELD_TEXT
                                            string: line
                                             store: LCStore_NO
                                             index: LCIndex_Tokenized];                                         
        LCField *f2 = [[LCField alloc] initWithName: FIELD_PATH
                                   string: [NSString stringWithFormat: @"some/path/to/%d", i]
                                    store: LCStore_YES
                                    index: LCIndex_NO];
        [d addField: f1];
        [d addField: f2];

        [f1 release];
        [f2 release];

        [writer addDocument: d];

        [d release];
        [line release];

        i++;
    }

    fclose(fh);

    S4DebugLog(@"closing writer");

    [writer close];    
    [writer release];
    [analyzer release];
}


- (LCFSDirectory *)createFileDirectory
{
    // FIXME should be the application support folder
    NSString *supportPath = [S4FileUtilities documentsDirectory];

    NSString *path = [supportPath stringByAppendingPathComponent: @"index.idx"];

    if ([[NSFileManager defaultManager] isReadableFileAtPath: path])
	{
        return [[LCFSDirectory alloc] initWithPath: path create: NO];
    }

    LCFSDirectory *rd = [[LCFSDirectory alloc] initWithPath: path create: YES];
    [self fillDirectory: rd];
    return rd;
}


- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [window makeKeyAndVisible];

    LCFSDirectory *rd = [self createFileDirectory];
    S4DebugLog(@"opening searcher");
	searcher = [[LCIndexSearcher alloc] initWithDirectory: rd];
    [rd release];
    S4DebugLog(@"ready");
    [resultField setText: @""];
}


- (void)searchBar: (UISearchBar *)searchBar textDidChange: (NSString *)searchText
{
    S4DebugLog(@"searching %@", searchText);

    LCTerm *t = [[LCTerm alloc] initWithField: FIELD_TEXT text: searchText];

    LCTermQuery *tq = [[LCTermQuery alloc] initWithTerm: t];

    LCHits *hits = [searcher search: tq];

    LCHitIterator *iterator = [hits iterator];
    
    while ([iterator hasNext])
	{
        LCHit *hit = [iterator next];
        S4DebugLog(@"%@ -> %@", hit, [hit stringForField: FIELD_PATH]);
    }

    int results = [hits count];

    [resultField setText: [NSString stringWithFormat: @"%d", results]];

}


- (void)dealloc
{
    NS_SAFE_RELEASE(searcher);
    NS_SAFE_RELEASE(window);
    NS_SAFE_RELEASE(searchBar);

    [super dealloc];
}


@end
