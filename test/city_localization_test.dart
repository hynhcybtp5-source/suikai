import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/data/models.dart';
import 'package:suikai/features/home/home_page.dart';
import 'package:suikai/services/suikai_service.dart';

void main() {
  const city = CityRecord(
    id: 'city-1',
    name: 'Mueang Nai',
    nameTh: 'เมืองนาย',
    nameShn: 'ဝဵင်းၼၢႆး',
    nameEn: 'Mueang Nai',
    nameMy: 'မိုင်းနိုင်မြို့',
  );

  test('city uses the application locale translation', () {
    expect(city.localizedName('th'), 'เมืองนาย');
    expect(city.localizedName('en'), 'Mueang Nai');
    expect(city.localizedName('my'), 'မိုင်းနိုင်မြို့');
    expect(city.localizedName('shn'), 'ဝဵင်းၼၢႆး');
  });

  test('missing translation falls back to English then primary name', () {
    const englishFallback = CityRecord(
      id: 'city-2',
      name: 'Primary name',
      nameEn: 'English name',
    );
    const primaryFallback = CityRecord(id: 'city-3', name: 'Primary name');

    expect(englishFallback.localizedName('my'), 'English name');
    expect(primaryFallback.localizedName('my'), 'Primary name');
  });

  test('listing keeps city while exact location remains private', () {
    final listing = ListingRecord.fromJson({
      'id': 'listing-1',
      'owner_id': 'owner-1',
      'title': 'Product',
      'city': 'Mueang Nai',
      'city_id': city.id,
      'cities': city.toJson(),
      'latitude': 20.0,
      'longitude': 98.0,
      'is_location_visible': false,
      'created_at': '2026-08-12T00:00:00Z',
      'updated_at': '2026-08-12T00:00:00Z',
    });

    expect(listing.cityRecord?.localizedName('th'), 'เมืองนาย');
    expect(listing.isLocationVisible, isFalse);

    final product = ProductViewModel(
      id: listing.id,
      title: listing.title,
      priceValue: listing.price.round(),
      description: listing.description,
      category: listing.category,
      city: listing.city,
      cityId: listing.cityId,
      cityRecord: listing.cityRecord,
      location: listing.city,
      time: '',
      image: '',
      phone: '',
      viber: '',
      likeCount: 0,
      viewCount: 0,
      status: ProductStatus.available,
      latitude: listing.latitude,
      longitude: listing.longitude,
      isLocationVisible: listing.isLocationVisible,
    );
    expect(product.localizedCity('th'), 'Mueang Nai');
    expect(product.publicLatitude, isNull);
    expect(product.publicLongitude, isNull);
  });

  test('different listings keep their own real city records', () {
    const otherCity = CityRecord(
      id: 'city-4',
      name: 'Other primary city',
      nameTh: 'เมืองอื่น',
    );
    expect(city.localizedName('th'), isNot(otherCity.localizedName('th')));
  });

  test('missing city uses the caller supplied localized fallback', () {
    const product = ProductViewModel(
      id: 'listing-without-city',
      title: 'Product',
      priceValue: 0,
      description: '',
      category: '',
      city: '',
      location: '',
      time: '',
      image: '',
      phone: '',
      viber: '',
      likeCount: 0,
      viewCount: 0,
      status: ProductStatus.available,
    );
    expect(
      product.localizedCity('en', fallback: 'City not specified'),
      'City not specified',
    );
  });

  test('legacy city id remains compatible with free-text city', () {
    SuikaiService.setCitiesForTesting(const [city]);
    expect(SuikaiService.activeCities.single.id, city.id);
    final profile = UserProfile.fromJson({
      'id': 'profile-1',
      'name': 'City owner',
      'phone': '0900000000',
      'email': 'city-owner@example.test',
      'city_id': city.id,
      'city': '  User City  ',
      'created_at': '2026-08-12T00:00:00Z',
    });
    expect(profile.cityId, city.id);
    expect(profile.city.trim(), 'User City');
    expect(profile.toJson()['city_id'], city.id);
  });
}
