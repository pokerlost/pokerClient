// Generated snapshot of pypokerlost.enums.ServiceId, SDK main
// c4d8327e8318eab6769b3f05c4a7d848c75afb0b. Review the owner diff before updating.
enum ServiceId {
  auth('authService'),
  accounts('accountsService'),
  virtualMoney('virtualMoney'),
  poker('pokerService'),
  crypto('cryptoService');

  const ServiceId(this.wire);
  final String wire;
}

const serviceIdHeader = 'x-pokerlost-serviceId';
