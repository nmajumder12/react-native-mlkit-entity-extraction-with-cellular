// MlkitEntityExtraction.m

#import "MlkitEntityExtraction.h"

@implementation MlkitEntityExtraction {
    MLKEntityExtractor *_entityExtractor;
    NSMutableSet *_typesFilter;
    id _downloadSuccessObserver;
    id _downloadFailObserver;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _typesFilter = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:_downloadSuccessObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:_downloadFailObserver];
    [_entityExtractor release];
    [_typesFilter release];
    [super dealloc];
}

- (void)clearTypesFilter {
    [_typesFilter removeAllObjects];
}

RCT_EXPORT_MODULE(MLKitEntityExtraction)

- (int)mapEntityType:(NSString *)type {
    if ([type isEqualToString:MLKEntityExtractionEntityTypeAddress]) {
        return 1;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypeDateTime]) {
        return 2;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypeEmail]) {
        return 3;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypeFlightNumber]) {
        return 4;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypeIBAN]) {
        return 5;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypeISBN]) {
        return 6;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypePaymentCard]) {
        return 7;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypePhone]) {
        return 8;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypeTrackingNumber]) {
        return 9;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypeURL]) {
        return 10;
    } else if ([type isEqualToString:MLKEntityExtractionEntityTypeMoney]) {
        return 11;
    }
    return -1;
}

- (NSString *)mapEntityTypeRev:(int)type {
    switch (type) {
        case 1:
            return MLKEntityExtractionEntityTypeAddress;
        case 2:
            return MLKEntityExtractionEntityTypeDateTime;
        case 3:
            return MLKEntityExtractionEntityTypeEmail;
        case 4:
            return MLKEntityExtractionEntityTypeFlightNumber;
        case 5:
            return MLKEntityExtractionEntityTypeIBAN;
        case 6:
            return MLKEntityExtractionEntityTypeISBN;
        case 7:
            return MLKEntityExtractionEntityTypePaymentCard;
        case 8:
            return MLKEntityExtractionEntityTypePhone;
        case 9:
            return MLKEntityExtractionEntityTypeTrackingNumber;
        case 10:
            return MLKEntityExtractionEntityTypeURL;
        case 11:
            return MLKEntityExtractionEntityTypeMoney;
        default:
            return @"";
    }
}

RCT_EXPORT_METHOD(annotate:(NSString *)text
                  lang:(NSString *)lang
                  types:(NSArray *)types
                  successCallback:(RCTResponseSenderBlock)successCallback
                  failCallback:(RCTResponseSenderBlock)failCallback) {
    MLKEntityExtractorOptions *options = [[MLKEntityExtractorOptions alloc] initWithModelIdentifier:MLKEntityExtractionModelIdentifierForLanguageTag(lang)];
    if (_entityExtractor == nil) {
        _entityExtractor = [[MLKEntityExtractor entityExtractorWithOptions:options] retain];
        [options release]; // Release options since it's not needed anymore
    }
    
    [self clearTypesFilter]; // Clear typesFilter before reusing
    
    for (NSNumber *tp in types) {
        NSString *tpstr = [self mapEntityTypeRev:[tp intValue]];
        if (![tpstr isEqualToString:@""]) {
            [_typesFilter addObject:tpstr]; // Add types to filter set
        }
    }
    
    MLKEntityExtractionParams *params = [[MLKEntityExtractionParams alloc] init];
    params.typesFilter = _typesFilter;
    
    [_entityExtractor annotateText:text
                        withParams:params
                        completion:^(NSArray *_Nullable entityAnnotations, NSError *_Nullable error) {
        if (error != nil) {
            failCallback(@[error.localizedDescription]);
            return;
        }
        NSMutableArray *annots = [[NSMutableArray alloc] init];
        for (MLKEntityAnnotation *entityAnnotation in entityAnnotations) {
            NSArray *entities = entityAnnotation.entities;
            NSMutableDictionary *annomap = [[NSMutableDictionary alloc] init];
            [annomap setObject:[text substringWithRange:entityAnnotation.range] forKey:@"annotation"];
            
            NSMutableArray *annoarr = [[NSMutableArray alloc] init];
            for (MLKEntity *entity in entities) {
                NSString *entityType = entity.entityType;
                int mappedType = [self mapEntityType:entityType];
                [annomap setObject:@(mappedType) forKey:@"type"];
                if ([entityType isEqualToString:MLKEntityExtractionEntityTypeDateTime]) {
                // Handle entity types as needed
                    MLKDateTimeEntity *dateTimeEntity = entity.dateTimeEntity;
                // ...
                    NSMutableDictionary *dateTimeMap = [[NSMutableDictionary alloc] init];
                    [dateTimeMap setObject:@((int)dateTimeEntity.dateTimeGranularity) forKey:@"granularity"];
                    [dateTimeMap setObject:@(dateTimeEntity.dateTime.timeIntervalSince1970) forKey:@"timestamp"];
                    [annoarr addObject:dateTimeMap];
                } else if ([entityType isEqualToString:MLKEntityExtractionEntityTypeFlightNumber]) {
                    MLKFlightNumberEntity *flightNumberEntity = entity.flightNumberEntity;
                    NSMutableDictionary *flightNumberMap = [[NSMutableDictionary alloc] init];
                    [flightNumberMap setObject:flightNumberEntity.airlineCode forKey:@"ariline_code"];
                    [flightNumberMap setObject:flightNumberEntity.flightNumber forKey:@"flight_number"];
                    [annoarr addObject:flightNumberMap];
                } else if ([entityType isEqualToString:MLKEntityExtractionEntityTypeIBAN]) {
                    MLKIBANEntity *ibanEntity = entity.IBANEntity;
                    NSMutableDictionary *ibanMap = [[NSMutableDictionary alloc] init];
                    [ibanMap setObject:ibanEntity.IBAN forKey:@"iban"];
                    [ibanMap setObject:ibanEntity.countryCode forKey:@"country_code"];
                    [annoarr addObject:ibanMap];
                } else if ([entityType isEqualToString:MLKEntityExtractionEntityTypeISBN]) {
                    MLKISBNEntity *isbnEntity = entity.ISBNEntity;
                    NSMutableDictionary *isbnMap = [[NSMutableDictionary alloc] init];
                    [isbnMap setObject:isbnEntity.ISBN forKey:@"isbn"];
                    [isbnMap setObject:@"" forKey:@"country_code"];
                    [annoarr addObject:isbnMap];
                } else if ([entityType isEqualToString:MLKEntityExtractionEntityTypePaymentCard]) {
                    MLKPaymentCardEntity *paymentCardEntity = entity.paymentCardEntity;
                    NSMutableDictionary *paymentCardMap = [[NSMutableDictionary alloc] init];
                    [paymentCardMap setObject:paymentCardEntity.paymentCardNumber forKey:@"card_number"];
                    [paymentCardMap setObject:@(paymentCardEntity.paymentCardNetwork) forKey:@"card_network"];
                    [annoarr addObject:paymentCardMap];
                } else if ([entityType isEqualToString:MLKEntityExtractionEntityTypeTrackingNumber]) {
                    MLKTrackingNumberEntity *trackingNumberEntity = entity.trackingNumberEntity;
                    NSMutableDictionary *trackingNumberMap = [[NSMutableDictionary alloc] init];
                    [trackingNumberMap setObject:trackingNumberEntity.parcelTrackingNumber forKey:@"tracking_number"];
                    [trackingNumberMap setObject:@(trackingNumberEntity.parcelCarrier) forKey:@"carrier"];
                    [annoarr addObject:trackingNumberMap];
                } else if ([entityType isEqualToString:MLKEntityExtractionEntityTypeMoney]) {
                    MLKMoneyEntity *moneyEntity = entity.moneyEntity;
                    NSMutableDictionary *moneyMap = [[NSMutableDictionary alloc] init];
                    [moneyMap setObject:moneyEntity.unnormalizedCurrency forKey:@"currency"];
                    [moneyMap setObject:@(moneyEntity.integerPart) forKey:@"integer_part"];
                    [moneyMap setObject:@(moneyEntity.fractionalPart) forKey:@"fractional_part"];
                    [annoarr addObject:moneyMap];
                }
            }
            if ([annoarr count] > 0) {
                [annomap setObject:annoarr forKey:@"entities"];
            }
            [annots addObject:annomap];
            [annoarr release]; // Release annoarr since it's not needed anymore
            [annomap release]; // Release annomap since it's not needed anymore
        }
        [params release]; // Release params since it's not needed anymore
        successCallback(@[annots]);
        [annots release]; // Release annots since it's not needed anymore
    }];
}

RCT_EXPORT_METHOD(isModelDownloaded:(NSString *)lang withCallback:(RCTResponseSenderBlock)callback) {
    MLKEntityExtractionRemoteModel *model = [MLKEntityExtractionRemoteModel entityExtractorRemoteModelWithIdentifier:MLKEntityExtractionModelIdentifierForLanguageTag(lang)];
    BOOL downloaded = [[MLKModelManager modelManager] isModelDownloaded:model];
    callback(@[@(downloaded)]);
}

RCT_EXPORT_METHOD(deleteDownloadedModel:(NSString *)lang
                  successCallback:(RCTResponseSenderBlock)successCallback
                  failCallback:(RCTResponseSenderBlock)failCallback) {
    MLKEntityExtractionRemoteModel *model = [MLKEntityExtractionRemoteModel entityExtractorRemoteModelWithIdentifier:MLKEntityExtractionModelIdentifierForLanguageTag(lang)];
    BOOL downloaded = [[MLKModelManager modelManager] isModelDownloaded:model];
    if (downloaded) {
        [[MLKModelManager modelManager] deleteDownloadedModel:model completion:^(NSError * _Nullable error) {
            if (error != nil) {
                failCallback(@[error.localizedDescription]);
            } else {
                successCallback(@[@"success"]);
            }
        }];
    }
}

RCT_EXPORT_METHOD(downloadModel:(NSString *)lang
                  successCallback:(RCTResponseSenderBlock)successCallback
                  failCallback:(RCTResponseSenderBlock)failCallback) {
    MLKModelDownloadConditions *conditions = [[MLKModelDownloadConditions alloc] initWithAllowsCellularAccess:NO allowsBackgroundDownloading:YES];
    MLKEntityExtractionRemoteModel *lmodel = [MLKEntityExtractionRemoteModel entityExtractorRemoteModelWithIdentifier:MLKEntityExtractionModelIdentifierForLanguageTag(lang)];
    
    _downloadSuccessObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MLKModelDownloadDidSucceedNotification
                                                                                   object:nil
                                                                                    queue:nil
                                                                               usingBlock:^(NSNotification * _Nonnull note) {
        MLKEntityExtractionRemoteModel *model = note.userInfo[MLKModelDownloadUserInfoKeyRemoteModel];
        if ([model isKindOfClass:[MLKEntityExtractionRemoteModel class]] && model == lmodel) {
            successCallback(@[@"success"]);
        }
        [[NSNotificationCenter defaultCenter] removeObserver:_downloadSuccessObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:_downloadFailObserver];
    }];
    
    _downloadFailObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MLKModelDownloadDidFailNotification
                                                                                object:nil
                                                                                 queue:nil
                                                                            usingBlock:^(NSNotification * _Nonnull note) {
        MLKEntityExtractionRemoteModel *model = note.userInfo[MLKModelDownloadUserInfoKeyRemoteModel];
        if ([model isKindOfClass:[MLKEntityExtractionRemoteModel class]] && model == lmodel) {
            NSError *error = note.userInfo[MLKModelDownloadUserInfoKeyError];
            failCallback(@[error.localizedDescription]);
        }
        [[NSNotificationCenter defaultCenter] removeObserver:_downloadSuccessObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:_downloadFailObserver];
    }];
    
    [[MLKModelManager modelManager] downloadModel:lmodel conditions:conditions];
}

@end
