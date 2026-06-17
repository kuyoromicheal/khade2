import '../models/models.dart';
import 'geo_utils.dart';

int calculateTravelFee({
  required ProviderModel provider,
  required double customerLat,
  required double customerLng,
}) {
  if (provider.providerType == 'salon') return 0;
  if (provider.latitude == null || provider.longitude == null) return provider.minTravelFee;

  final distance = haversineKm(customerLat, customerLng, provider.latitude!, provider.longitude!);
  if (distance > provider.travelRadiusKm) return -1; // outside radius

  if (provider.travelFeePerKm > 0) {
    final fee = (distance * provider.travelFeePerKm).round();
    return fee < provider.minTravelFee ? provider.minTravelFee : fee;
  }
  return 0;
}
