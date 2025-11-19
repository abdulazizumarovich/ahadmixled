// import '../../constants/imports.dart';

// AppBar defaultAppBar({bool openProfile = true, PreferredSizeWidget? bottom, List<Widget>? actions}) {
//   return AppBar(
//     backgroundColor: AppColors.primaryColor,
//     toolbarHeight: Get.height * 0.12,
//     centerTitle: false,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(
//         bottom: Radius.circular(30),
//       ),
//     ),
//     iconTheme: const IconThemeData(color: Colors.white),
//     title: Consumer<ProfileProvider>(builder: (context, profileProvider, child) {
//       return GestureDetector(
//         onTap: () {
//           if (openProfile) {
//             Get.toNamed(Routes.profile);
//           }
//         },
//         child: Row(
//           children: [
//             profileProvider.profile == null || profileProvider.profile!.imgUrl.isEmpty
//                 ? const Icon(CupertinoIcons.person_alt_circle, color: Colors.white, size: 60)
//                 : ClipRRect(
//                     borderRadius: BorderRadius.circular(180),
//                     child: NetworkImageShimmer(
//                       imageUrl: '$domain/${profileProvider.profile!.imgUrl}',
//                       width: 60,
//                       height: 60,
//                     )),
//             const Gap(10),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '${profileProvider.profile?.name} ${profileProvider.profile?.surname}',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 18.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   if (openProfile) const Gap(10),
//                   if (openProfile)
//                     Row(
//                       children: [
//                         SvgPicture.asset(LocalImages.coins, width: 35),
//                         Text('${profileProvider.profile?.id} ${'sum'.tr}', style: const TextStyle(color: Colors.white))
//                       ],
//                     )
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }),
//     bottom: bottom,
//     actions: actions,
//   );
// }
