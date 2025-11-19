import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tv_monitor/features/presentation/blocs/device/device_bloc.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Device Information', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<DeviceBloc, DeviceState>(
        builder: (context, state) {
          if (state is DeviceLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          if (state is DeviceInfoLoaded) {
            final deviceInfo = state.deviceInfo;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('General Information'),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    _buildInfoRow('Brand', deviceInfo.brand),
                    _buildInfoRow('Model', deviceInfo.model),
                    _buildInfoRow('Manufacturer', deviceInfo.manufacturer),
                    _buildInfoRow('OS Version', deviceInfo.osVersion),
                    _buildInfoRow('App Version', deviceInfo.appVersion),
                    _buildInfoRow('Serial Number', deviceInfo.snNumber),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Display Information'),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    _buildInfoRow('Screen Resolution', deviceInfo.screenResolution, icon: Icons.monitor),
                    _buildInfoRow('Brightness', '${deviceInfo.brightness}%', icon: Icons.brightness_medium),
                    _buildInfoRow('Volume', '${deviceInfo.volume}%', icon: Icons.volume_up),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Storage Information'),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    _buildInfoRow('Total Storage', deviceInfo.totalStorage, icon: Icons.storage),
                    _buildInfoRow('Free Storage', deviceInfo.freeStorage, icon: Icons.sd_storage),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Network Information'),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    _buildInfoRow('IP Address', deviceInfo.ipAddress ?? 'Not available', icon: Icons.wifi),
                    _buildInfoRow('MAC Address', deviceInfo.macAddress ?? 'Not available', icon: Icons.router),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }

          if (state is DeviceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DeviceBloc>().add(const GetDeviceInfo());
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.shade700),
                    child: const Text('Retry', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No device information available', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<DeviceBloc>().add(const GetDeviceInfo());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.shade700),
                  child: const Text('Load Device Info', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 0.5)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: Colors.cyanAccent.shade700, size: 24), const SizedBox(width: 16)],
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
