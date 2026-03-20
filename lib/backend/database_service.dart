import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/models.dart';

/// Provides typed CRUD for all Supabase tables.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ── Users ─────────────────────────────────────────────────

  Future<UserRow?> getUser(String uid) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return data != null ? UserRow.fromJson(data) : null;
  }

  Future<UserRow> upsertUser(UserRow user) async {
    final data = await _client
        .from('users')
        .upsert(user.toJson())
        .select()
        .single();
    return UserRow.fromJson(data);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _client.from('users').update(fields).eq('id', uid);
  }

  // ── Listings ──────────────────────────────────────────────

  Future<List<ListingRow>> getListings({
    String? city,
    String? propertyType,
    String? category,
    int? maxPrice,
    int? minPrice,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('listings').select();
      // Try filtering by status — some DBs may not have this column populated
      query = query.eq('status', 'active');
      if (city != null) {
        query = query.or('prop_city.ilike.%$city%,property_name.ilike.%$city%');
      }
      if (propertyType != null) {
        query = query.eq('property_type', propertyType);
      }
      if (maxPrice != null) query = query.lte('price', maxPrice);
      if (minPrice != null) query = query.gte('price', minPrice);
      final data = await query.limit(limit);
      return (data as List).map((e) => ListingRow.fromJson(e)).toList();
    } catch (_) {
      // Fallback: try without status filter
      try {
        var query = _client.from('listings').select();
        if (city != null) {
          query = query.or(
            'prop_city.ilike.%$city%,property_name.ilike.%$city%',
          );
        }
        if (propertyType != null) {
          query = query.eq('property_type', propertyType);
        }
        if (maxPrice != null) query = query.lte('price', maxPrice);
        if (minPrice != null) query = query.gte('price', minPrice);
        final data = await query.limit(limit);
        return (data as List).map((e) => ListingRow.fromJson(e)).toList();
      } catch (_) {
        return <ListingRow>[];
      }
    }
  }

  /// Calls the Supabase Postgres Function `get_properties_in_radius`
  Future<List<ListingRow>> getListingsInRadius(
    double lat,
    double lng, {
    double radiusKm = 10.0,
  }) async {
    try {
      final data = await _client.rpc(
        'get_properties_in_radius',
        params: {'search_lat': lat, 'search_lng': lng, 'radius_km': radiusKm},
      );
      return (data as List).map((e) => ListingRow.fromJson(e)).toList();
    } catch (e) {
      // Return empty list if the RPC fails (e.g., function not created yet)
      return const <ListingRow>[];
    }
  }

  Future<ListingRow?> getListing(String id) async {
    final data = await _client
        .from('listings')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data != null ? ListingRow.fromJson(data) : null;
  }

  Future<List<ListingRow>> getListingsByOwner(String ownerId) async {
    try {
      // In this schema, the property ID is exactly the same as the landlord's auth UID.
      // So a landlord can only have one listing, and its ID is their UID.
      final data = await _client.from('listings').select().eq('id', ownerId);
      return (data as List).map((e) => ListingRow.fromJson(e)).toList();
    } catch (_) {
      return const <ListingRow>[];
    }
  }

  Future<ListingRow> insertListing(ListingRow listing) async {
    final data = await _client
        .from('listings')
        .insert(listing.toJson())
        .select()
        .single();
    return ListingRow.fromJson(data);
  }

  Future<void> updateListing(String id, Map<String, dynamic> fields) async {
    await _client.from('listings').update(fields).eq('id', id);
  }

  Future<void> deleteListing(String id) async {
    await _client.from('listings').delete().eq('id', id);
  }

  // ── Booking ───────────────────────────────────────────────

  Future<BookingRow> insertBooking(BookingRow booking) async {
    final data = await _client
        .from('booking')
        .insert(booking.toJson())
        .select()
        .single();
    return BookingRow.fromJson(data);
  }

  Future<List<BookingRow>> getBookingsForUser(String uid) async {
    final data = await _client.from('booking').select().eq('id', uid);
    return (data as List).map((e) => BookingRow.fromJson(e)).toList();
  }

  // ── Confirm Booking ───────────────────────────────────────

  Future<ConfirmBookingRow> insertConfirmBooking(ConfirmBookingRow row) async {
    final data = await _client
        .from('confirm booking page')
        .insert(row.toJson())
        .select()
        .single();
    return ConfirmBookingRow.fromJson(data);
  }

  // ── View Room Card ────────────────────────────────────────

  Future<List<ViewRoomCardRow>> getViewRoomCards(String uid) async {
    try {
      final data = await _client.from('view_room_card').select().eq('id', uid);
      return (data as List).map((e) => ViewRoomCardRow.fromJson(e)).toList();
    } catch (_) {
      return <ViewRoomCardRow>[];
    }
  }

  Future<ViewRoomCardRow> upsertViewRoomCard(ViewRoomCardRow row) async {
    final data = await _client
        .from('view_room_card')
        .upsert(row.toJson())
        .select()
        .single();
    return ViewRoomCardRow.fromJson(data);
  }

  Future<void> updateViewRoomCard(
    String id,
    Map<String, dynamic> fields,
  ) async {
    await _client.from('view_room_card').update(fields).eq('id', id);
  }

  // ── Favourites ────────────────────────────────────────────

  Future<List<FavouriteRow>> getFavourites(String uid) async {
    final data = await _client.from('favourite').select().eq('id', uid);
    return (data as List).map((e) => FavouriteRow.fromJson(e)).toList();
  }

  Future<FavouriteRow> insertFavourite(FavouriteRow row) async {
    final data = await _client
        .from('favourite')
        .insert(row.toJson())
        .select()
        .single();
    return FavouriteRow.fromJson(data);
  }

  Future<void> deleteFavourite(String id) async {
    await _client.from('favourite').delete().eq('id', id);
  }

  // ── Payment Details (Landlord) ────────────────────────────

  Future<PaymentDetailsLandlordRow?> getLandlordPaymentDetails(
    String uid,
  ) async {
    final data = await _client
        .from('payment_details_lanlord')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return data != null ? PaymentDetailsLandlordRow.fromJson(data) : null;
  }

  Future<PaymentDetailsLandlordRow> upsertLandlordPaymentDetails(
    PaymentDetailsLandlordRow row,
  ) async {
    final data = await _client
        .from('payment_details_lanlord')
        .upsert(row.toJson())
        .select()
        .single();
    return PaymentDetailsLandlordRow.fromJson(data);
  }
}
