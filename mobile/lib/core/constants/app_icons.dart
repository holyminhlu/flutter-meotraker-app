/// Asset paths for icons in `assets/icons/`.
class AppIcons {
  static const String chieuCao = 'assets/icons/01_chieu_cao.png';
  static const String khungGioNhacNho =
      'assets/icons/01_cai_dat_khung_gio_nhac_nho.png';
  static const String canNang = 'assets/icons/02_can_nang.png';
  static const String chupAnhAi = 'assets/icons/uploadCamera.png';
  static const String mucTieu = 'assets/icons/03_muc_tieu.png';
  static const String thanhPhanDinhDuong =
      'assets/icons/03_thanh_phan_dinh_duong.png';
  static const String anMungDatMoc = 'assets/icons/04_an_mung_dat_moc.png';
  static const String goiYMonAn = 'assets/icons/04_goi_y_mon_an_thay_the.png';
  static const String nhuCauCalo = 'assets/icons/04_nhu_cau_calo.png';
  static const String lichSuBieuDo = 'assets/icons/05_lich_su_bieu_do_calo.png';
  static const String soThich = 'assets/icons/05_so_thich.png';
  static const String diUng = 'assets/icons/06_di_ung.png';
  static const String quyenRiengTu = 'assets/icons/06_quyen_rieng_tu.png';
  static const String uongNuocAm = 'assets/icons/06_uong_nuoc_am.png';
  static const String nganSach = 'assets/icons/07_ngan_sach.png';
  static const String vanDongNhe = 'assets/icons/07_van_dong_nhe.png';
  static const String giacNgu = 'assets/icons/08_giac_ngu.png';
  static const String khungGio = 'assets/icons/08_khung_gio_nhac_nho.png';
  static const String nhatKyCamNhan = 'assets/icons/08_nhat_ky_cam_nhan.png';
  static const String chupAnhAiAlt = 'assets/icons/uploadCamera.png';
  static const String uploadCamera = 'assets/icons/uploadCamera.png';
  static const String diemThuong = 'assets/icons/xu.png';
  static const String xu = 'assets/icons/xu.png';
  static const String streak = 'assets/icons/streak.png';
  static const String streak7 = 'assets/icons/streak/streak7ngay.png';
  static const String streak30 = 'assets/icons/streak/streak30ngay.png';
  static const String streak90 = 'assets/icons/streak/streak90ngay.png';
  static const String streak120 = 'assets/icons/streak/streak120ngay.png';

  /// Icon streak theo số ngày; đứt chuỗi / &lt; 7 → streak.png gốc.
  static String streakForDays(int days) {
    if (days >= 120) return streak120;
    if (days >= 90) return streak90;
    if (days >= 30) return streak30;
    if (days >= 7) return streak7;
    return streak;
  }

  // Banners / images
  static const String ruongVip = 'assets/images/ruong15d.png';
  static const String ruongSuperVip = 'assets/images/ruong30d.png';
  static const String buaSang = 'assets/images/buaSang.png';
  static const String buaTrua = 'assets/images/buatrua.png';
  static const String buaToi = 'assets/images/buaToi.png';
}
