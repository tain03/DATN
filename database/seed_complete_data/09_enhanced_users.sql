-- ============================================
-- ENHANCED USER DATA - Realistic & Diverse
-- ============================================
-- Purpose: Add 150+ more users with realistic profiles and progression
-- Database: auth_db, user_db
-- Date: 2025-11-07
-- ============================================

\c auth_db

-- Add 150 more realistic users with diverse backgrounds
INSERT INTO users (id, email, username, email_verified, created_at, last_login) VALUES
-- Beginner users (Band 3-4) - 40 users
('550e8400-e29b-41d4-a716-446655440101', 'nguyen.van.a@gmail.com', 'nguyen_van_a', true, NOW() - INTERVAL '90 days', NOW() - INTERVAL '2 hours'),
('550e8400-e29b-41d4-a716-446655440102', 'tran.thi.b@gmail.com', 'tran_thi_b', true, NOW() - INTERVAL '85 days', NOW() - INTERVAL '5 hours'),
('550e8400-e29b-41d4-a716-446655440103', 'le.minh.c@gmail.com', 'le_minh_c', true, NOW() - INTERVAL '80 days', NOW() - INTERVAL '1 day'),
('550e8400-e29b-41d4-a716-446655440104', 'pham.thu.d@gmail.com', 'pham_thu_d', true, NOW() - INTERVAL '75 days', NOW() - INTERVAL '3 hours'),
('550e8400-e29b-41d4-a716-446655440105', 'hoang.van.e@gmail.com', 'hoang_van_e', true, NOW() - INTERVAL '70 days', NOW() - INTERVAL '8 hours'),
('550e8400-e29b-41d4-a716-446655440106', 'vu.thi.f@yahoo.com', 'vu_thi_f', true, NOW() - INTERVAL '68 days', NOW() - INTERVAL '12 hours'),
('550e8400-e29b-41d4-a716-446655440107', 'do.minh.g@outlook.com', 'do_minh_g', true, NOW() - INTERVAL '65 days', NOW() - INTERVAL '2 days'),
('550e8400-e29b-41d4-a716-446655440108', 'bui.thu.h@gmail.com', 'bui_thu_h', true, NOW() - INTERVAL '63 days', NOW() - INTERVAL '6 hours'),
('550e8400-e29b-41d4-a716-446655440109', 'ngo.van.i@gmail.com', 'ngo_van_i', true, NOW() - INTERVAL '60 days', NOW() - INTERVAL '15 hours'),
('550e8400-e29b-41d4-a716-446655440110', 'dang.thi.j@gmail.com', 'dang_thi_j', true, NOW() - INTERVAL '58 days', NOW() - INTERVAL '1 hour'),
('550e8400-e29b-41d4-a716-446655440111', 'phan.minh.k@gmail.com', 'phan_minh_k', true, NOW() - INTERVAL '55 days', NOW() - INTERVAL '20 hours'),
('550e8400-e29b-41d4-a716-446655440112', 'ly.thu.l@gmail.com', 'ly_thu_l', true, NOW() - INTERVAL '53 days', NOW() - INTERVAL '4 days'),
('550e8400-e29b-41d4-a716-446655440113', 'truong.van.m@gmail.com', 'truong_van_m', true, NOW() - INTERVAL '50 days', NOW() - INTERVAL '9 hours'),
('550e8400-e29b-41d4-a716-446655440114', 'dinh.thi.n@gmail.com', 'dinh_thi_n', true, NOW() - INTERVAL '48 days', NOW() - INTERVAL '14 hours'),
('550e8400-e29b-41d4-a716-446655440115', 'ta.minh.o@gmail.com', 'ta_minh_o', true, NOW() - INTERVAL '45 days', NOW() - INTERVAL '18 hours'),
('550e8400-e29b-41d4-a716-446655440116', 'mac.thu.p@yahoo.com', 'mac_thu_p', true, NOW() - INTERVAL '43 days', NOW() - INTERVAL '22 hours'),
('550e8400-e29b-41d4-a716-446655440117', 'ha.van.q@gmail.com', 'ha_van_q', true, NOW() - INTERVAL '40 days', NOW() - INTERVAL '3 days'),
('550e8400-e29b-41d4-a716-446655440118', 'trinh.thi.r@gmail.com', 'trinh_thi_r', true, NOW() - INTERVAL '38 days', NOW() - INTERVAL '7 hours'),
('550e8400-e29b-41d4-a716-446655440119', 'cao.minh.s@gmail.com', 'cao_minh_s', true, NOW() - INTERVAL '35 days', NOW() - INTERVAL '11 hours'),
('550e8400-e29b-41d4-a716-446655440120', 'luu.thu.t@gmail.com', 'luu_thu_t', true, NOW() - INTERVAL '33 days', NOW() - INTERVAL '16 hours'),
('550e8400-e29b-41d4-a716-446655440121', 'tong.van.u@gmail.com', 'tong_van_u', true, NOW() - INTERVAL '30 days', NOW() - INTERVAL '5 days'),
('550e8400-e29b-41d4-a716-446655440122', 'duong.thi.v@gmail.com', 'duong_thi_v', true, NOW() - INTERVAL '28 days', NOW() - INTERVAL '19 hours'),
('550e8400-e29b-41d4-a716-446655440123', 'bach.minh.w@outlook.com', 'bach_minh_w', true, NOW() - INTERVAL '25 days', NOW() - INTERVAL '13 hours'),
('550e8400-e29b-41d4-a716-446655440124', 'doan.thu.x@gmail.com', 'doan_thu_x', true, NOW() - INTERVAL '23 days', NOW() - INTERVAL '17 hours'),
('550e8400-e29b-41d4-a716-446655440125', 'tu.van.y@gmail.com', 'tu_van_y', true, NOW() - INTERVAL '20 days', NOW() - INTERVAL '21 hours'),
('550e8400-e29b-41d4-a716-446655440126', 'quan.thi.z@gmail.com', 'quan_thi_z', true, NOW() - INTERVAL '18 days', NOW() - INTERVAL '6 days'),
('550e8400-e29b-41d4-a716-446655440127', 'khuc.minh.aa@gmail.com', 'khuc_minh_aa', true, NOW() - INTERVAL '15 days', NOW() - INTERVAL '10 hours'),
('550e8400-e29b-41d4-a716-446655440128', 'mai.thu.bb@gmail.com', 'mai_thu_bb', true, NOW() - INTERVAL '13 days', NOW() - INTERVAL '14 hours'),
('550e8400-e29b-41d4-a716-446655440129', 'kieu.van.cc@gmail.com', 'kieu_van_cc', true, NOW() - INTERVAL '10 days', NOW() - INTERVAL '18 hours'),
('550e8400-e29b-41d4-a716-446655440130', 'ung.thi.dd@yahoo.com', 'ung_thi_dd', true, NOW() - INTERVAL '8 days', NOW() - INTERVAL '22 hours'),
('550e8400-e29b-41d4-a716-446655440131', 'uyen.minh.ee@gmail.com', 'uyen_minh_ee', true, NOW() - INTERVAL '6 days', NOW() - INTERVAL '7 days'),
('550e8400-e29b-41d4-a716-446655440132', 'yen.thu.ff@gmail.com', 'yen_thu_ff', true, NOW() - INTERVAL '4 days', NOW() - INTERVAL '12 hours'),
('550e8400-e29b-41d4-a716-446655440133', 'nghiem.van.gg@gmail.com', 'nghiem_van_gg', true, NOW() - INTERVAL '2 days', NOW() - INTERVAL '16 hours'),
('550e8400-e29b-41d4-a716-446655440134', 'thach.thi.hh@gmail.com', 'thach_thi_hh', true, NOW() - INTERVAL '1 day', NOW() - INTERVAL '20 hours'),
('550e8400-e29b-41d4-a716-446655440135', 'sieu.minh.ii@gmail.com', 'sieu_minh_ii', false, NOW() - INTERVAL '12 hours', NOW() - INTERVAL '2 hours'),
('550e8400-e29b-41d4-a716-446655440136', 'lam.thu.jj@gmail.com', 'lam_thu_jj', false, NOW() - INTERVAL '8 hours', NOW() - INTERVAL '1 hour'),
('550e8400-e29b-41d4-a716-446655440137', 'hung.van.kk@outlook.com', 'hung_van_kk', false, NOW() - INTERVAL '6 hours', NOW() - INTERVAL '30 minutes'),
('550e8400-e29b-41d4-a716-446655440138', 'hien.thi.ll@gmail.com', 'hien_thi_ll', false, NOW() - INTERVAL '4 hours', NOW() - INTERVAL '15 minutes'),
('550e8400-e29b-41d4-a716-446655440139', 'thinh.minh.mm@gmail.com', 'thinh_minh_mm', false, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '5 minutes'),
('550e8400-e29b-41d4-a716-446655440140', 'thao.thu.nn@gmail.com', 'thao_thu_nn', false, NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 minute'),

-- Intermediate users (Band 5-6) - 60 users
('550e8400-e29b-41d4-a716-446655440201', 'john.smith@gmail.com', 'john_smith_ielts', true, NOW() - INTERVAL '180 days', NOW() - INTERVAL '3 hours'),
('550e8400-e29b-41d4-a716-446655440202', 'emily.johnson@outlook.com', 'emily_j_study', true, NOW() - INTERVAL '175 days', NOW() - INTERVAL '1 day'),
('550e8400-e29b-41d4-a716-446655440203', 'michael.brown@gmail.com', 'michael_ielts', true, NOW() - INTERVAL '170 days', NOW() - INTERVAL '6 hours'),
('550e8400-e29b-41d4-a716-446655440204', 'sarah.davis@yahoo.com', 'sarah_d_english', true, NOW() - INTERVAL '165 days', NOW() - INTERVAL '9 hours'),
('550e8400-e29b-41d4-a716-446655440205', 'david.wilson@gmail.com', 'david_w_ielts', true, NOW() - INTERVAL '160 days', NOW() - INTERVAL '2 days'),
('550e8400-e29b-41d4-a716-446655440206', 'jessica.martinez@gmail.com', 'jessica_m_study', true, NOW() - INTERVAL '155 days', NOW() - INTERVAL '12 hours'),
('550e8400-e29b-41d4-a716-446655440207', 'james.anderson@outlook.com', 'james_a_english', true, NOW() - INTERVAL '150 days', NOW() - INTERVAL '15 hours'),
('550e8400-e29b-41d4-a716-446655440208', 'ashley.taylor@gmail.com', 'ashley_t_ielts', true, NOW() - INTERVAL '145 days', NOW() - INTERVAL '18 hours'),
('550e8400-e29b-41d4-a716-446655440209', 'chris.thomas@gmail.com', 'chris_t_study', true, NOW() - INTERVAL '140 days', NOW() - INTERVAL '3 days'),
('550e8400-e29b-41d4-a716-446655440210', 'amanda.jackson@yahoo.com', 'amanda_j_ielts', true, NOW() - INTERVAL '135 days', NOW() - INTERVAL '21 hours'),
('550e8400-e29b-41d4-a716-446655440211', 'matthew.white@gmail.com', 'matthew_w_english', true, NOW() - INTERVAL '130 days', NOW() - INTERVAL '4 hours'),
('550e8400-e29b-41d4-a716-446655440212', 'jennifer.harris@gmail.com', 'jennifer_h_study', true, NOW() - INTERVAL '125 days', NOW() - INTERVAL '7 hours'),
('550e8400-e29b-41d4-a716-446655440213', 'daniel.martin@outlook.com', 'daniel_m_ielts', true, NOW() - INTERVAL '120 days', NOW() - INTERVAL '10 hours'),
('550e8400-e29b-41d4-a716-446655440214', 'lisa.thompson@gmail.com', 'lisa_t_english', true, NOW() - INTERVAL '115 days', NOW() - INTERVAL '4 days'),
('550e8400-e29b-41d4-a716-446655440215', 'kevin.garcia@gmail.com', 'kevin_g_ielts', true, NOW() - INTERVAL '110 days', NOW() - INTERVAL '13 hours'),
-- Add 45 more intermediate users with Vietnamese and International names
('550e8400-e29b-41d4-a716-446655440216', 'tran.minh.anh@gmail.com', 'minh_anh_ielts', true, NOW() - INTERVAL '108 days', NOW() - INTERVAL '5 hours'),
('550e8400-e29b-41d4-a716-446655440217', 'nguyen.hoang.bao@gmail.com', 'hoang_bao_study', true, NOW() - INTERVAL '106 days', NOW() - INTERVAL '8 hours'),
('550e8400-e29b-41d4-a716-446655440218', 'le.thu.cuc@yahoo.com', 'thu_cuc_english', true, NOW() - INTERVAL '104 days', NOW() - INTERVAL '11 hours'),
('550e8400-e29b-41d4-a716-446655440219', 'pham.quoc.dat@gmail.com', 'quoc_dat_ielts', true, NOW() - INTERVAL '102 days', NOW() - INTERVAL '5 days'),
('550e8400-e29b-41d4-a716-446655440220', 'hoang.kim.e@outlook.com', 'kim_e_study', true, NOW() - INTERVAL '100 days', NOW() - INTERVAL '14 hours'),
('550e8400-e29b-41d4-a716-446655440221', 'wang.li@gmail.com', 'wang_li_ielts', true, NOW() - INTERVAL '98 days', NOW() - INTERVAL '2 hours'),
('550e8400-e29b-41d4-a716-446655440222', 'tanaka.yuki@gmail.com', 'yuki_tanaka_study', true, NOW() - INTERVAL '96 days', NOW() - INTERVAL '17 hours'),
('550e8400-e29b-41d4-a716-446655440223', 'kim.min.jun@naver.com', 'minjun_kim_ielts', true, NOW() - INTERVAL '94 days', NOW() - INTERVAL '20 hours'),
('550e8400-e29b-41d4-a716-446655440224', 'chen.wei@qq.com', 'chen_wei_english', true, NOW() - INTERVAL '92 days', NOW() - INTERVAL '6 days'),
('550e8400-e29b-41d4-a716-446655440225', 'sato.hiroshi@gmail.com', 'hiroshi_sato_ielts', true, NOW() - INTERVAL '90 days', NOW() - INTERVAL '23 hours'),
('550e8400-e29b-41d4-a716-446655440226', 'park.seo.jun@gmail.com', 'seojun_park_study', true, NOW() - INTERVAL '88 days', NOW() - INTERVAL '3 hours'),
('550e8400-e29b-41d4-a716-446655440227', 'liu.xiao.ming@163.com', 'xiaoming_liu_ielts', true, NOW() - INTERVAL '86 days', NOW() - INTERVAL '16 hours'),
('550e8400-e29b-41d4-a716-446655440228', 'yamamoto.kenji@yahoo.jp', 'kenji_yamamoto_english', true, NOW() - INTERVAL '84 days', NOW() - INTERVAL '19 hours'),
('550e8400-e29b-41d4-a716-446655440229', 'lee.ji.woo@kakao.com', 'jiwoo_lee_ielts', true, NOW() - INTERVAL '82 days', NOW() - INTERVAL '7 days'),
('550e8400-e29b-41d4-a716-446655440230', 'zhang.hua@gmail.com', 'zhang_hua_study', true, NOW() - INTERVAL '80 days', NOW() - INTERVAL '22 hours'),
('550e8400-e29b-41d4-a716-446655440231', 'suzuki.akira@gmail.com', 'akira_suzuki_ielts', true, NOW() - INTERVAL '78 days', NOW() - INTERVAL '4 hours'),
('550e8400-e29b-41d4-a716-446655440232', 'choi.min.ji@naver.com', 'minji_choi_english', true, NOW() - INTERVAL '76 days', NOW() - INTERVAL '15 hours'),
('550e8400-e29b-41d4-a716-446655440233', 'huang.jie@qq.com', 'huang_jie_study', true, NOW() - INTERVAL '74 days', NOW() - INTERVAL '8 days'),
('550e8400-e29b-41d4-a716-446655440234', 'takahashi.yui@gmail.com', 'yui_takahashi_ielts', true, NOW() - INTERVAL '72 days', NOW() - INTERVAL '18 hours'),
('550e8400-e29b-41d4-a716-446655440235', 'kang.ha.neul@kakao.com', 'haneul_kang_english', true, NOW() - INTERVAL '70 days', NOW() - INTERVAL '21 hours'),
('550e8400-e29b-41d4-a716-446655440236', 'wu.fang@163.com', 'wu_fang_ielts', true, NOW() - INTERVAL '68 days', NOW() - INTERVAL '9 days'),
('550e8400-e29b-41d4-a716-446655440237', 'nakamura.ryo@yahoo.jp', 'ryo_nakamura_study', true, NOW() - INTERVAL '66 days', NOW() - INTERVAL '1 hour'),
('550e8400-e29b-41d4-a716-446655440238', 'jang.dong.gun@gmail.com', 'donggun_jang_ielts', true, NOW() - INTERVAL '64 days', NOW() - INTERVAL '24 hours'),
('550e8400-e29b-41d4-a716-446655440239', 'li.na@gmail.com', 'li_na_english', true, NOW() - INTERVAL '62 days', NOW() - INTERVAL '10 days'),
('550e8400-e29b-41d4-a716-446655440240', 'kobayashi.mai@gmail.com', 'mai_kobayashi_study', true, NOW() - INTERVAL '60 days', NOW() - INTERVAL '5 hours'),
('550e8400-e29b-41d4-a716-446655440241', 'shin.se.kyung@naver.com', 'sekyung_shin_ielts', true, NOW() - INTERVAL '58 days', NOW() - INTERVAL '8 hours'),
('550e8400-e29b-41d4-a716-446655440242', 'zhao.lei@qq.com', 'zhao_lei_english', true, NOW() - INTERVAL '56 days', NOW() - INTERVAL '11 days'),
('550e8400-e29b-41d4-a716-446655440243', 'ito.sakura@gmail.com', 'sakura_ito_study', true, NOW() - INTERVAL '54 days', NOW() - INTERVAL '11 hours'),
('550e8400-e29b-41d4-a716-446655440244', 'song.hye.kyo@kakao.com', 'hyekyo_song_ielts', true, NOW() - INTERVAL '52 days', NOW() - INTERVAL '14 hours'),
('550e8400-e29b-41d4-a716-446655440245', 'xu.qiang@163.com', 'xu_qiang_english', true, NOW() - INTERVAL '50 days', NOW() - INTERVAL '12 days'),
('550e8400-e29b-41d4-a716-446655440246', 'watanabe.ken@yahoo.jp', 'ken_watanabe_ielts', true, NOW() - INTERVAL '48 days', NOW() - INTERVAL '17 hours'),
('550e8400-e29b-41d4-a716-446655440247', 'baek.seung.heon@gmail.com', 'seungheon_baek_study', true, NOW() - INTERVAL '46 days', NOW() - INTERVAL '20 hours'),
('550e8400-e29b-41d4-a716-446655440248', 'gao.yang@gmail.com', 'gao_yang_ielts', true, NOW() - INTERVAL '44 days', NOW() - INTERVAL '13 days'),
('550e8400-e29b-41d4-a716-446655440249', 'ono.takeshi@gmail.com', 'takeshi_ono_english', true, NOW() - INTERVAL '42 days', NOW() - INTERVAL '23 hours'),
('550e8400-e29b-41d4-a716-446655440250', 'han.ga.in@naver.com', 'gain_han_study', true, NOW() - INTERVAL '40 days', NOW() - INTERVAL '2 hours'),
('550e8400-e29b-41d4-a716-446655440251', 'sun.li@qq.com', 'sun_li_ielts', true, NOW() - INTERVAL '38 days', NOW() - INTERVAL '14 days'),
('550e8400-e29b-41d4-a716-446655440252', 'fujita.rina@gmail.com', 'rina_fujita_english', true, NOW() - INTERVAL '36 days', NOW() - INTERVAL '5 hours'),
('550e8400-e29b-41d4-a716-446655440253', 'yoon.eun.hye@kakao.com', 'eunhye_yoon_study', true, NOW() - INTERVAL '34 days', NOW() - INTERVAL '8 hours'),
('550e8400-e29b-41d4-a716-446655440254', 'ma.jun@163.com', 'ma_jun_ielts', true, NOW() - INTERVAL '32 days', NOW() - INTERVAL '15 days'),
('550e8400-e29b-41d4-a716-446655440255', 'ishikawa.ren@yahoo.jp', 'ren_ishikawa_english', true, NOW() - INTERVAL '30 days', NOW() - INTERVAL '11 hours'),
('550e8400-e29b-41d4-a716-446655440256', 'jung.so.min@gmail.com', 'somin_jung_study', true, NOW() - INTERVAL '28 days', NOW() - INTERVAL '14 hours'),
('550e8400-e29b-41d4-a716-446655440257', 'qian.wei@gmail.com', 'qian_wei_ielts', true, NOW() - INTERVAL '26 days', NOW() - INTERVAL '16 days'),
('550e8400-e29b-41d4-a716-446655440258', 'mori.aoi@gmail.com', 'aoi_mori_english', true, NOW() - INTERVAL '24 days', NOW() - INTERVAL '17 hours'),
('550e8400-e29b-41d4-a716-446655440259', 'go.ara@naver.com', 'ara_go_study', true, NOW() - INTERVAL '22 days', NOW() - INTERVAL '20 hours'),
('550e8400-e29b-41d4-a716-446655440260', 'luo.bin@qq.com', 'luo_bin_ielts', true, NOW() - INTERVAL '20 days', NOW() - INTERVAL '17 days'),

-- Advanced users (Band 7-8.5) - 50 users
('550e8400-e29b-41d4-a716-446655440301', 'sophia.anderson@cambridge.edu', 'sophia_adv_ielts', true, NOW() - INTERVAL '365 days', NOW() - INTERVAL '1 hour'),
('550e8400-e29b-41d4-a716-446655440302', 'oliver.thomson@oxford.ac.uk', 'oliver_master_english', true, NOW() - INTERVAL '350 days', NOW() - INTERVAL '4 hours'),
('550e8400-e29b-41d4-a716-446655440303', 'emma.williams@gmail.com', 'emma_ielts_pro', true, NOW() - INTERVAL '340 days', NOW() - INTERVAL '7 hours'),
('550e8400-e29b-41d4-a716-446655440304', 'liam.robinson@harvard.edu', 'liam_expert_study', true, NOW() - INTERVAL '330 days', NOW() - INTERVAL '10 hours'),
('550e8400-e29b-41d4-a716-446655440305', 'ava.martinez@stanford.edu', 'ava_advanced_ielts', true, NOW() - INTERVAL '320 days', NOW() - INTERVAL '2 days'),
('550e8400-e29b-41d4-a716-446655440306', 'noah.johnson@yale.edu', 'noah_pro_english', true, NOW() - INTERVAL '310 days', NOW() - INTERVAL '13 hours'),
('550e8400-e29b-41d4-a716-446655440307', 'isabella.davis@mit.edu', 'isabella_expert_ielts', true, NOW() - INTERVAL '300 days', NOW() - INTERVAL '16 hours'),
('550e8400-e29b-41d4-a716-446655440308', 'ethan.miller@columbia.edu', 'ethan_adv_study', true, NOW() - INTERVAL '290 days', NOW() - INTERVAL '19 hours'),
('550e8400-e29b-41d4-a716-446655440309', 'mia.wilson@princeton.edu', 'mia_master_ielts', true, NOW() - INTERVAL '280 days', NOW() - INTERVAL '3 days'),
('550e8400-e29b-41d4-a716-446655440310', 'lucas.brown@uchicago.edu', 'lucas_pro_english', true, NOW() - INTERVAL '270 days', NOW() - INTERVAL '22 hours'),
('550e8400-e29b-41d4-a716-446655440311', 'charlotte.taylor@duke.edu', 'charlotte_expert_study', true, NOW() - INTERVAL '260 days', NOW() - INTERVAL '1 hour'),
('550e8400-e29b-41d4-a716-446655440312', 'mason.moore@berkeley.edu', 'mason_adv_ielts', true, NOW() - INTERVAL '250 days', NOW() - INTERVAL '4 days'),
('550e8400-e29b-41d4-a716-446655440313', 'amelia.jackson@cornell.edu', 'amelia_master_english', true, NOW() - INTERVAL '240 days', NOW() - INTERVAL '4 hours'),
('550e8400-e29b-41d4-a716-446655440314', 'harper.lee@upenn.edu', 'harper_pro_study', true, NOW() - INTERVAL '230 days', NOW() - INTERVAL '7 hours'),
('550e8400-e29b-41d4-a716-446655440315', 'evelyn.white@northwestern.edu', 'evelyn_expert_ielts', true, NOW() - INTERVAL '220 days', NOW() - INTERVAL '5 days'),
('550e8400-e29b-41d4-a716-446655440316', 'nguyen.duc.minh@hust.edu.vn', 'ducminh_advanced', true, NOW() - INTERVAL '210 days', NOW() - INTERVAL '10 hours'),
('550e8400-e29b-41d4-a716-446655440317', 'tran.thu.thao@vnu.edu.vn', 'thuthao_expert', true, NOW() - INTERVAL '200 days', NOW() - INTERVAL '13 hours'),
('550e8400-e29b-41d4-a716-446655440318', 'le.quang.huy@rmit.edu.vn', 'quanghuy_ielts_pro', true, NOW() - INTERVAL '190 days', NOW() - INTERVAL '6 days'),
('550e8400-e29b-41d4-a716-446655440319', 'pham.lan.anh@ftu.edu.vn', 'lananh_master', true, NOW() - INTERVAL '180 days', NOW() - INTERVAL '16 hours'),
('550e8400-e29b-41d4-a716-446655440320', 'hoang.minh.tue@ntu.edu.sg', 'minhtue_advanced', true, NOW() - INTERVAL '170 days', NOW() - INTERVAL '19 hours'),
('550e8400-e29b-41d4-a716-446655440321', 'tanaka.haruto@todai.ac.jp', 'haruto_expert_ielts', true, NOW() - INTERVAL '365 days', NOW() - INTERVAL '2 hours'),
('550e8400-e29b-41d4-a716-446655440322', 'kim.soo.hyun@snu.ac.kr', 'soohyun_pro_study', true, NOW() - INTERVAL '355 days', NOW() - INTERVAL '5 hours'),
('550e8400-e29b-41d4-a716-446655440323', 'wang.xiu.ying@tsinghua.edu.cn', 'xiuying_adv_ielts', true, NOW() - INTERVAL '345 days', NOW() - INTERVAL '8 hours'),
('550e8400-e29b-41d4-a716-446655440324', 'sato.ayumi@kyoto-u.ac.jp', 'ayumi_master_english', true, NOW() - INTERVAL '335 days', NOW() - INTERVAL '7 days'),
('550e8400-e29b-41d4-a716-446655440325', 'park.ji.sung@yonsei.ac.kr', 'jisung_expert_study', true, NOW() - INTERVAL '325 days', NOW() - INTERVAL '11 hours'),
('550e8400-e29b-41d4-a716-446655440326', 'chen.jia.ming@pku.edu.cn', 'jiaming_pro_ielts', true, NOW() - INTERVAL '315 days', NOW() - INTERVAL '14 hours'),
('550e8400-e29b-41d4-a716-446655440327', 'yamada.kaito@osaka-u.ac.jp', 'kaito_adv_english', true, NOW() - INTERVAL '305 days', NOW() - INTERVAL '8 days'),
('550e8400-e29b-41d4-a716-446655440328', 'lee.min.ho@kaist.ac.kr', 'minho_master_study', true, NOW() - INTERVAL '295 days', NOW() - INTERVAL '17 hours'),
('550e8400-e29b-41d4-a716-446655440329', 'liu.yu.chen@fudan.edu.cn', 'yuchen_expert_ielts', true, NOW() - INTERVAL '285 days', NOW() - INTERVAL '20 hours'),
('550e8400-e29b-41d4-a716-446655440330', 'nakajima.hina@waseda.jp', 'hina_pro_english', true, NOW() - INTERVAL '275 days', NOW() - INTERVAL '9 days'),
('550e8400-e29b-41d4-a716-446655440331', 'choi.ye.jin@skku.edu', 'yejin_adv_study', true, NOW() - INTERVAL '265 days', NOW() - INTERVAL '23 hours'),
('550e8400-e29b-41d4-a716-446655440332', 'zhang.rui.xuan@sjtu.edu.cn', 'ruixuan_master_ielts', true, NOW() - INTERVAL '255 days', NOW() - INTERVAL '2 hours'),
('550e8400-e29b-41d4-a716-446655440333', 'honda.shiori@keio.ac.jp', 'shiori_expert_english', true, NOW() - INTERVAL '245 days', NOW() - INTERVAL '10 days'),
('550e8400-e29b-41d4-a716-446655440334', 'bae.su.ji@postech.ac.kr', 'suji_pro_study', true, NOW() - INTERVAL '235 days', NOW() - INTERVAL '5 hours'),
('550e8400-e29b-41d4-a716-446655440335', 'huang.zi.xuan@zju.edu.cn', 'zixuan_adv_ielts', true, NOW() - INTERVAL '225 days', NOW() - INTERVAL '8 hours'),
('550e8400-e29b-41d4-a716-446655440336', 'suzuki.ren@hokudai.ac.jp', 'ren_master_english', true, NOW() - INTERVAL '215 days', NOW() - INTERVAL '11 days'),
('550e8400-e29b-41d4-a716-446655440337', 'kwon.na.ra@hanyang.ac.kr', 'nara_expert_study', true, NOW() - INTERVAL '205 days', NOW() - INTERVAL '11 hours'),
('550e8400-e29b-41d4-a716-446655440338', 'wu.si.yu@ustc.edu.cn', 'siyu_pro_ielts', true, NOW() - INTERVAL '195 days', NOW() - INTERVAL '14 hours'),
('550e8400-e29b-41d4-a716-446655440339', 'takahashi.sora@tohoku.ac.jp', 'sora_adv_english', true, NOW() - INTERVAL '185 days', NOW() - INTERVAL '12 days'),
('550e8400-e29b-41d4-a716-446655440340', 'im.yoon.ah@ewha.ac.kr', 'yoonah_master_study', true, NOW() - INTERVAL '175 days', NOW() - INTERVAL '17 hours'),
('550e8400-e29b-41d4-a716-446655440341', 'zhao.yi.han@ntu.edu.cn', 'yihan_expert_ielts', true, NOW() - INTERVAL '165 days', NOW() - INTERVAL '20 hours'),
('550e8400-e29b-41d4-a716-446655440342', 'kobayashi.airi@nagoya-u.jp', 'airi_pro_english', true, NOW() - INTERVAL '155 days', NOW() - INTERVAL '13 days'),
('550e8400-e29b-41d4-a716-446655440343', 'kang.da.hee@cau.ac.kr', 'dahee_adv_study', true, NOW() - INTERVAL '145 days', NOW() - INTERVAL '23 hours'),
('550e8400-e29b-41d4-a716-446655440344', 'xu.yi.ting@buaa.edu.cn', 'yiting_master_ielts', true, NOW() - INTERVAL '135 days', NOW() - INTERVAL '2 hours'),
('550e8400-e29b-41d4-a716-446655440345', 'matsumoto.haruka@kyushu-u.jp', 'haruka_expert_english', true, NOW() - INTERVAL '125 days', NOW() - INTERVAL '14 days'),
('550e8400-e29b-41d4-a716-446655440346', 'shin.hye.sun@sogang.ac.kr', 'hyesun_pro_study', true, NOW() - INTERVAL '115 days', NOW() - INTERVAL '5 hours'),
('550e8400-e29b-41d4-a716-446655440347', 'gao.yu.qing@hit.edu.cn', 'yuqing_adv_ielts', true, NOW() - INTERVAL '105 days', NOW() - INTERVAL '8 hours'),
('550e8400-e29b-41d4-a716-446655440348', 'fujimoto.nana@tsukuba.ac.jp', 'nana_master_english', true, NOW() - INTERVAL '95 days', NOW() - INTERVAL '15 days'),
('550e8400-e29b-41d4-a716-446655440349', 'jung.eun.ji@khu.ac.kr', 'eunji_expert_study', true, NOW() - INTERVAL '85 days', NOW() - INTERVAL '11 hours'),
('550e8400-e29b-41d4-a716-446655440350', 'jiang.mei.li@whu.edu.cn', 'meili_pro_ielts', true, NOW() - INTERVAL '75 days', NOW() - INTERVAL '14 hours')
ON CONFLICT (id) DO NOTHING;

RAISE NOTICE '✅ Enhanced Users: Added 150 diverse users (40 beginners, 60 intermediate, 50 advanced)';

-- ============================================
-- USER_DB - Profiles for new users
-- ============================================
\c user_db

-- Create profiles for all new users
INSERT INTO user_profiles (
    id, full_name, phone, date_of_birth, country, city, 
    timezone, avatar_url, bio, target_band_score, 
    target_test_date, study_hours_per_week, preferred_study_time, 
    notification_enabled, created_at, updated_at
)
SELECT 
    u.id,
    CASE 
        WHEN u.username LIKE 'nguyen%' THEN 'Nguyễn ' || INITCAP(REPLACE(SPLIT_PART(u.username, '_', 3), '_', ' '))
        WHEN u.username LIKE 'tran%' THEN 'Trần ' || INITCAP(REPLACE(SPLIT_PART(u.username, '_', 3), '_', ' '))
        WHEN u.username LIKE 'le%' THEN 'Lê ' || INITCAP(REPLACE(SPLIT_PART(u.username, '_', 3), '_', ' '))
        WHEN u.username LIKE 'pham%' THEN 'Phạm ' || INITCAP(REPLACE(SPLIT_PART(u.username, '_', 3), '_', ' '))
        WHEN u.username LIKE 'hoang%' THEN 'Hoàng ' || INITCAP(REPLACE(SPLIT_PART(u.username, '_', 3), '_', ' '))
        WHEN u.username LIKE 'john%' THEN 'John Smith'
        WHEN u.username LIKE 'emily%' THEN 'Emily Johnson'
        WHEN u.username LIKE 'michael%' THEN 'Michael Brown'
        WHEN u.username LIKE 'sarah%' THEN 'Sarah Davis'
        WHEN u.username LIKE 'david%' THEN 'David Wilson'
        WHEN u.username LIKE '%tanaka%' OR u.username LIKE '%sato%' OR u.username LIKE '%yamamoto%' THEN INITCAP(REPLACE(u.username, '_', ' '))
        WHEN u.username LIKE '%kim%' OR u.username LIKE '%park%' OR u.username LIKE '%lee%' THEN INITCAP(REPLACE(u.username, '_', ' '))
        WHEN u.username LIKE '%wang%' OR u.username LIKE '%chen%' OR u.username LIKE '%liu%' THEN INITCAP(REPLACE(u.username, '_', ' '))
        WHEN u.username LIKE 'sophia%' THEN 'Sophia Anderson'
        WHEN u.username LIKE 'oliver%' THEN 'Oliver Thomson'
        WHEN u.username LIKE 'emma%' THEN 'Emma Williams'
        ELSE INITCAP(REPLACE(u.username, '_', ' '))
    END as full_name,
    CASE 
        WHEN u.email LIKE '%@gmail.com' AND u.id::text LIKE '%-4401%' THEN '+84' || LPAD((RANDOM() * 900000000 + 100000000)::BIGINT::TEXT, 9, '0')
        WHEN u.email LIKE '%@yahoo.com%' AND u.id::text LIKE '%-4401%' THEN '+84' || LPAD((RANDOM() * 900000000 + 100000000)::BIGINT::TEXT, 9, '0')
        WHEN u.id::text LIKE '%-4402%' OR u.id::text LIKE '%-4403%' THEN '+1' || LPAD((RANDOM() * 9000000000 + 1000000000)::BIGINT::TEXT, 10, '0')
        ELSE NULL
    END as phone,
    NOW() - INTERVAL '20 years' - (RANDOM() * INTERVAL '15 years') as date_of_birth,
    CASE 
        WHEN u.id::text LIKE '%-4401%' THEN 'Vietnam'
        WHEN u.username LIKE '%tanaka%' OR u.username LIKE '%sato%' OR u.username LIKE '%yamamoto%' OR u.username LIKE '%nakamura%' OR u.username LIKE '%kobayashi%' THEN 'Japan'
        WHEN u.username LIKE '%kim%' OR u.username LIKE '%park%' OR u.username LIKE '%lee%' AND u.email LIKE '%@naver.com%' THEN 'South Korea'
        WHEN u.username LIKE '%wang%' OR u.username LIKE '%chen%' OR u.username LIKE '%liu%' OR u.username LIKE '%zhang%' THEN 'China'
        WHEN u.id::text LIKE '%-4403%' THEN 
            (ARRAY['USA', 'UK', 'Canada', 'Australia', 'Singapore'])[FLOOR(RANDOM() * 5 + 1)]
        ELSE 'Vietnam'
    END as country,
    CASE 
        WHEN u.id::text LIKE '%-4401%' THEN (ARRAY['Hà Nội', 'Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ'])[FLOOR(RANDOM() * 5 + 1)]
        WHEN u.username LIKE '%tanaka%' OR u.username LIKE '%sato%' THEN (ARRAY['Tokyo', 'Osaka', 'Kyoto', 'Fukuoka'])[FLOOR(RANDOM() * 4 + 1)]
        WHEN u.username LIKE '%kim%' OR u.username LIKE '%park%' THEN (ARRAY['Seoul', 'Busan', 'Incheon', 'Daegu'])[FLOOR(RANDOM() * 4 + 1)]
        WHEN u.username LIKE '%wang%' OR u.username LIKE '%chen%' THEN (ARRAY['Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen'])[FLOOR(RANDOM() * 4 + 1)]
        ELSE (ARRAY['New York', 'London', 'Toronto', 'Sydney', 'Singapore'])[FLOOR(RANDOM() * 5 + 1)]
    END as city,
    CASE 
        WHEN u.id::text LIKE '%-4401%' THEN 'Asia/Ho_Chi_Minh'
        WHEN u.username LIKE '%tanaka%' OR u.username LIKE '%sato%' THEN 'Asia/Tokyo'
        WHEN u.username LIKE '%kim%' OR u.username LIKE '%park%' THEN 'Asia/Seoul'
        WHEN u.username LIKE '%wang%' OR u.username LIKE '%chen%' THEN 'Asia/Shanghai'
        WHEN country = 'USA' THEN 'America/New_York'
        WHEN country = 'UK' THEN 'Europe/London'
        WHEN country = 'Australia' THEN 'Australia/Sydney'
        ELSE 'UTC'
    END as timezone,
    'https://ui-avatars.com/api/?name=' || REPLACE(u.username, '_', '+') || '&background=random' as avatar_url,
    CASE 
        WHEN u.id::text LIKE '%-4401%' THEN 'Đang học IELTS để đi du học. Mục tiêu band 6.5-7.0'
        WHEN u.id::text LIKE '%-4402%' THEN 'Preparing for IELTS to study abroad. Target band 6.5-7.5'
        WHEN u.id::text LIKE '%-4403%' THEN 'Advanced IELTS learner aiming for band 8.0+. Focus on academic writing and speaking fluency.'
        ELSE 'IELTS learner'
    END as bio,
    CASE 
        WHEN u.id::text LIKE '%-4401%' THEN (RANDOM() * 2 + 5.0)::NUMERIC(3,1) -- 5.0-7.0
        WHEN u.id::text LIKE '%-4402%' THEN (RANDOM() * 2 + 6.0)::NUMERIC(3,1) -- 6.0-8.0
        WHEN u.id::text LIKE '%-4403%' THEN (RANDOM() * 1.5 + 7.5)::NUMERIC(3,1) -- 7.5-9.0
        ELSE 6.5
    END as target_band_score,
    NOW() + (RANDOM() * INTERVAL '180 days') as target_test_date,
    CASE 
        WHEN u.id::text LIKE '%-4401%' THEN (RANDOM() * 10 + 5)::INT -- 5-15 hours
        WHEN u.id::text LIKE '%-4402%' THEN (RANDOM() * 15 + 10)::INT -- 10-25 hours
        WHEN u.id::text LIKE '%-4403%' THEN (RANDOM() * 20 + 15)::INT -- 15-35 hours
        ELSE 10
    END as study_hours_per_week,
    (ARRAY['morning', 'afternoon', 'evening', 'night'])[FLOOR(RANDOM() * 4 + 1)]::VARCHAR as preferred_study_time,
    true as notification_enabled,
    u.created_at,
    u.last_login
FROM dblink(
    'dbname=auth_db user=ielts_admin',
    'SELECT id, email, username, created_at, last_login FROM users WHERE id::text LIKE ''550e8400-e29b-41d4-a716-4466554401%'' OR id::text LIKE ''550e8400-e29b-41d4-a716-4466554402%'' OR id::text LIKE ''550e8400-e29b-41d4-a716-4466554403%'''
) AS u(id UUID, email TEXT, username TEXT, created_at TIMESTAMP, last_login TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

RAISE NOTICE '✅ User Profiles: Created profiles for 150 new users with realistic data';

-- ============================================
-- SUMMARY
-- ============================================
DO $$
DECLARE
    auth_count INT;
    profile_count INT;
BEGIN
    SELECT COUNT(*) INTO auth_count FROM dblink(
        'dbname=auth_db user=ielts_admin',
        'SELECT COUNT(*) FROM users'
    ) AS t(count BIGINT);
    
    SELECT COUNT(*) INTO profile_count FROM user_profiles;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Enhanced Users Summary:';
    RAISE NOTICE '  Total auth users: %', auth_count;
    RAISE NOTICE '  Total user profiles: %', profile_count;
    RAISE NOTICE '  Beginner users (Band 3-4): 40';
    RAISE NOTICE '  Intermediate users (Band 5-6): 60';
    RAISE NOTICE '  Advanced users (Band 7-8.5): 50';
    RAISE NOTICE '============================================';
END $$;
