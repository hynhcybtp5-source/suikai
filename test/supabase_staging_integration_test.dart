import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/data/models.dart';
import 'package:suikai/data/supabase_repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _publicKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const _serviceKey = String.fromEnvironment('SUPABASE_TEST_SERVICE_KEY');

void main() {
  if (_url.isEmpty || _publicKey.isEmpty || _serviceKey.isEmpty) {
    test(
      'Supabase staging integration requires explicit test defines',
      () {},
      skip: 'Staging credentials were not provided',
    );
    return;
  }

  test(
    'staging Flutter client respects Marketplace RLS',
    () async {
      final client = SupabaseClient(_url, _publicKey);
      final service = SupabaseClient(_url, _serviceKey);
      final suffix = DateTime.now().microsecondsSinceEpoch;
      const password = 'Staging-RLS-Only-42!';
      final emails = {
        'normal': 'normal-$suffix@staging.suikai.test',
        'suspended': 'suspended-$suffix@staging.suikai.test',
        'owner': 'owner-$suffix@staging.suikai.test',
        'admin': 'admin-$suffix@staging.suikai.test',
      };
      final ids = <String, String>{};
      String? storeId, generalListingId, storeProductId;
      Directory? tempDirectory;
      final uploadedObjects = <({String bucket, String path})>[];

      try {
        for (final entry in emails.entries) {
          final response = await service.auth.admin.createUser(
            AdminUserAttributes(
              email: entry.value,
              password: password,
              emailConfirm: true,
              userMetadata: {'name': entry.key, 'role': 'admin'},
            ),
          );
          ids[entry.key] = response.user!.id;
        }
        await service
            .from('profiles')
            .update({'status': 'suspended'})
            .eq('id', ids['suspended']!);
        await service.from('admin_roles').insert({
          'user_id': ids['admin'],
          'role': 'admin',
        });

        await client.auth.signOut();
        final categoryRepository = SupabaseCategoryRepository(client);
        final storeCategories = await categoryRepository.getByType(
          'store',
          activeOnly: true,
        );
        final listingCategories = await categoryRepository.getByType(
          'listing',
          activeOnly: true,
        );
        expect(storeCategories.length, 15);
        expect(listingCategories.length, 8);
        await expectLater(
          client.from('profiles').select(),
          throwsA(isA<PostgrestException>()),
        );

        final normalProfile = await SupabaseAuthRepository(
          client,
        ).login(emails['normal']!, password);
        expect(normalProfile.id, ids['normal']);
        expect((await client.from('profiles').select()).length, 1);
        await client
            .from('profiles')
            .update({'name': 'Normal Updated'})
            .eq('id', ids['normal']!);
        await expectLater(
          client
              .from('profiles')
              .update({'status': 'suspended'})
              .eq('id', ids['normal']!),
          throwsA(isA<PostgrestException>()),
        );

        await client.auth.signInWithPassword(
          email: emails['suspended']!,
          password: password,
        );
        expect((await client.from('profiles').select()).length, 1);
        final suspendedUpdate = await client
            .from('profiles')
            .update({'name': 'Must Not Change'})
            .eq('id', ids['suspended']!)
            .select();
        expect(suspendedUpdate, isEmpty);

        await client.auth.signInWithPassword(
          email: emails['owner']!,
          password: password,
        );
        tempDirectory = await Directory.systemTemp.createTemp(
          'suikai-staging-e2e-',
        );
        final imageFile = File('${tempDirectory.path}/image.png');
        await imageFile.writeAsBytes(const [137, 80, 78, 71]);
        final storage = SupabaseStorageService(client);
        final profileImageUrl = await storage.persistImage(
          imageFile.path,
          'png',
        );
        final ownerProfileRepository = SupabaseProfileRepository(client);
        final ownerProfile = await ownerProfileRepository.get(ids['owner']!);
        await ownerProfileRepository.save(
          UserProfile(
            id: ownerProfile!.id,
            name: ownerProfile.name,
            phone: ownerProfile.phone,
            email: ownerProfile.email,
            avatar: profileImageUrl,
            createdAt: ownerProfile.createdAt,
          ),
        );
        final avatarRelation = await client
            .from('profiles')
            .select('avatar_media_id')
            .eq('id', ids['owner']!)
            .single();
        expect(avatarRelation['avatar_media_id'], isNotNull);

        storeId = const Uuid().v4();
        final storeLogoUrl = await storage.persistImage(
          imageFile.path,
          'png',
          bucket: 'store-images',
          objectPrefix: 'stores/drafts/${ids['owner']}/$storeId',
        );
        await SupabaseStoreRepository(client).create(
          StoreRecord(
            id: storeId,
            ownerId: ids['owner']!,
            name: 'RLS Test Store',
            logo: storeLogoUrl,
            description: 'Staging integration store',
            category: storeCategories.first.id,
            phone: '0900000000',
            viber: '0900000000',
            city: 'Taunggyi',
            location: 'Staging',
            openingHours: '09:00 - 18:00',
            status: 'pending',
            createdAt: DateTime.now(),
          ),
        );
        final storeMediaRelation = await client
            .from('stores')
            .select('logo_media_id')
            .eq('id', storeId)
            .single();
        expect(storeMediaRelation['logo_media_id'], isNotNull);

        generalListingId = const Uuid().v4();
        final firstListingImageUrl = await storage.persistImage(
          imageFile.path,
          'png',
          bucket: 'listing-images',
          objectPrefix: 'listings/drafts/${ids['owner']}/$generalListingId',
        );
        final secondListingImageUrl = await storage.persistImage(
          imageFile.path,
          'png',
          bucket: 'listing-images',
          objectPrefix: 'listings/drafts/${ids['owner']}/$generalListingId',
        );
        final listingRepository = SupabaseListingRepository(client);
        final listing = ListingRecord(
          id: generalListingId,
          ownerId: ids['owner']!,
          title: 'RLS Test Listing',
          description: 'Created through the Flutter repository',
          category: listingCategories.last.id,
          price: 100,
          currency: 'MMK',
          city: 'Taunggyi',
          status: 'available',
          images: [firstListingImageUrl, secondListingImageUrl],
          phone: '0900000000',
          viber: '0900000000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await listingRepository.create(listing);
        final listingMediaRelations = await client
            .from('listing_images')
            .select('media_id')
            .eq('listing_id', generalListingId);
        expect(listingMediaRelations, hasLength(2));
        expect(
          listingMediaRelations.every((row) => row['media_id'] != null),
          isTrue,
        );

        await client.auth.signInWithPassword(
          email: emails['admin']!,
          password: password,
        );
        expect(await client.rpc('is_active_admin'), isTrue);
        expect((await client.from('profiles').select()).length, 4);
        await expectLater(
          client
              .from('admin_roles')
              .update({'is_active': false})
              .eq('user_id', ids['admin']!),
          throwsA(isA<PostgrestException>()),
        );
        await client.rpc(
          'review_store_application',
          params: {'p_store_id': storeId, 'p_approved': true},
        );

        await client.auth.signInWithPassword(
          email: emails['owner']!,
          password: password,
        );
        final notificationRepository = SupabaseNotificationRepository(client);
        expect(await notificationRepository.unreadCount(), 1);
        final notifications = await notificationRepository.all();
        expect(notifications.single.eventType, 'store_application_approved');
        await notificationRepository.markRead(notifications.single.id);
        expect(await notificationRepository.unreadCount(), 0);

        storeProductId = const Uuid().v4();
        final storeProductImageUrl = await storage.persistImage(
          imageFile.path,
          'png',
          bucket: 'listing-images',
          objectPrefix: 'listings/drafts/${ids['owner']}/$storeProductId',
        );
        final storeProduct = ListingRecord(
          id: storeProductId,
          ownerId: ids['owner']!,
          storeId: storeId,
          title: 'RLS Store Product',
          description: 'Store product lifecycle test',
          category: listingCategories.last.id,
          price: 50,
          currency: 'MMK',
          city: 'Taunggyi',
          status: 'available',
          images: [storeProductImageUrl],
          phone: '0900000000',
          viber: '0900000000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final ownerListingRepository = SupabaseListingRepository(client);
        await ownerListingRepository.create(storeProduct);
        final productMediaRelation = await client
            .from('listing_images')
            .select('media_id')
            .eq('listing_id', storeProductId)
            .single();
        expect(productMediaRelation['media_id'], isNotNull);

        await client.auth.signOut();
        expect(await SupabaseNotificationRepository(client).all(), isEmpty);
        final publicRows = await client
            .from('listings')
            .select('id')
            .eq('id', generalListingId);
        expect(publicRows.length, 1);
        final repositoryRows = await SupabaseListingRepository(client).all();
        expect(
          repositoryRows.where((row) => row.id == generalListingId),
          hasLength(1),
        );
        expect(
          await client.rpc(
            'toggle_listing_like',
            params: {
              'p_listing_id': generalListingId,
              'p_device_id': 'staging-device-$suffix',
            },
          ),
          isTrue,
        );
        expect(
          await client.rpc(
            'toggle_listing_like',
            params: {
              'p_listing_id': generalListingId,
              'p_device_id': 'staging-device-$suffix',
            },
          ),
          isFalse,
        );
        await client.rpc(
          'record_listing_view',
          params: {
            'p_listing_id': generalListingId,
            'p_device_id': 'staging-device-$suffix',
          },
        );
        await SupabaseReportRepository(client).create(
          ReportRecord(
            id: const Uuid().v4(),
            reason: 'Automated staging RLS test',
            targetId: generalListingId,
            type: 'listing',
            createdAt: DateTime.now(),
          ),
        );

        await client.auth.signInWithPassword(
          email: emails['owner']!,
          password: password,
        );
        final firstImageMedia = await client
            .from('listing_images')
            .select('media_id')
            .eq('listing_id', generalListingId)
            .eq('sort_order', 0)
            .single();
        final removedImageMedia = await client
            .from('listing_images')
            .select('media_id')
            .eq('listing_id', generalListingId)
            .eq('sort_order', 1)
            .single();
        final retainedMediaId = '${firstImageMedia['media_id']}';
        final removedMediaId = '${removedImageMedia['media_id']}';
        await ownerListingRepository.update(
          ListingRecord(
            id: listing.id,
            ownerId: listing.ownerId,
            title: 'RLS Test Listing Edited',
            description: listing.description,
            category: listing.category,
            price: 125,
            currency: listing.currency,
            city: listing.city,
            status: 'reserved',
            images: [firstListingImageUrl],
            phone: listing.phone,
            viber: listing.viber,
            createdAt: listing.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
        expect(
          await client
              .from('media_assets')
              .select('id')
              .eq('id', retainedMediaId),
          hasLength(1),
        );
        expect(
          await client
              .from('media_assets')
              .select('id')
              .eq('id', removedMediaId),
          isEmpty,
        );
        final reserved = (await ownerListingRepository.all()).singleWhere(
          (row) => row.id == generalListingId,
        );
        expect(reserved.status, 'reserved');
        await ownerListingRepository.update(
          ListingRecord(
            id: reserved.id,
            ownerId: reserved.ownerId,
            title: reserved.title,
            description: reserved.description,
            category: reserved.category,
            price: reserved.price,
            currency: reserved.currency,
            city: reserved.city,
            status: 'sold',
            images: reserved.images,
            phone: reserved.phone,
            viber: reserved.viber,
            createdAt: reserved.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
        await ownerListingRepository.update(
          ListingRecord(
            id: storeProduct.id,
            ownerId: storeProduct.ownerId,
            storeId: storeProduct.storeId,
            title: storeProduct.title,
            description: storeProduct.description,
            category: storeProduct.category,
            price: storeProduct.price,
            currency: storeProduct.currency,
            city: storeProduct.city,
            status: 'out_of_stock',
            images: storeProduct.images,
            phone: storeProduct.phone,
            viber: storeProduct.viber,
            createdAt: storeProduct.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
        final outOfStock = (await ownerListingRepository.all()).singleWhere(
          (row) => row.id == storeProductId,
        );
        expect(outOfStock.status, 'out_of_stock');
        await ownerListingRepository.update(
          ListingRecord(
            id: outOfStock.id,
            ownerId: outOfStock.ownerId,
            storeId: outOfStock.storeId,
            title: outOfStock.title,
            description: outOfStock.description,
            category: outOfStock.category,
            price: outOfStock.price,
            currency: outOfStock.currency,
            city: outOfStock.city,
            status: 'deleted',
            images: outOfStock.images,
            phone: outOfStock.phone,
            viber: outOfStock.viber,
            createdAt: outOfStock.createdAt,
            updatedAt: DateTime.now(),
          ),
        );

        await client.auth.signOut();
        expect(
          await client.from('listings').select('id').eq('id', generalListingId),
          isEmpty,
        );
        await client.auth.signInWithPassword(
          email: emails['owner']!,
          password: password,
        );
        final persistedRows = await SupabaseListingRepository(client).all();
        expect(
          persistedRows.singleWhere((row) => row.id == generalListingId).status,
          'sold',
        );
        expect(
          persistedRows.singleWhere((row) => row.id == storeProductId).status,
          'deleted',
        );
      } finally {
        await client.auth.signOut();
        if (generalListingId != null) {
          await service
              .from('reports')
              .delete()
              .eq('listing_id', generalListingId);
        }
        for (final id in ids.values) {
          final mediaRows = await service
              .from('media_assets')
              .select('bucket, object_path')
              .eq('owner_id', id);
          for (final row in mediaRows) {
            uploadedObjects.add((
              bucket: '${row['bucket']}',
              path: '${row['object_path']}',
            ));
          }
        }
        for (final id in ids.values) {
          await service.from('listings').delete().eq('owner_id', id);
          await service.from('stores').delete().eq('owner_id', id);
          await service.from('media_assets').delete().eq('owner_id', id);
          await service.auth.admin.deleteUser(id);
        }
        for (final object in uploadedObjects) {
          await service.storage.from(object.bucket).remove([object.path]);
        }
        await tempDirectory?.delete(recursive: true);
        client.dispose();
        service.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
