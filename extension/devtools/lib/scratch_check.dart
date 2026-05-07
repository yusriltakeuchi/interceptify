import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:vm_service/vm_service.dart';

void check() {
  Future<VmService> f = serviceManager.onServiceAvailable;
}
