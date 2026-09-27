-- ============================================================================
-- GOOGLE PLAY İNCELEME HESABI (27.09.2026, Cem "1 yap" — kapalı test incelemesi)
--
-- NEDEN: Play incelemesi "Uygulama erişimi" için kilitli bölümleri görebilecek bir test hesabı istiyor.
-- Hesabı CEM uygulamadan açar (e-posta: inceleme@tetikte.com; şifreyi yalnız Cem bilir, Play Console'a Cem yazar).
-- Bu SQL o hesaba TAM paket tanımlar (tüm sınavlar), 31.12.2027'ye kadar.
-- ÖNCE hesap açılmış olmalı: yoksa 0 satır etkilenir (sonuçta "0 rows" görünür → hesap henüz yok).
-- GERİ ALMA: delete from paket_uyeler where user_id = (select id from auth.users where email = 'inceleme@tetikte.com');
-- ============================================================================

insert into paket_uyeler (user_id, paket, bitis)
select id, 'tam', date '2027-12-31' from auth.users where email = 'inceleme@tetikte.com'
on conflict (user_id) do update set paket = 'tam', bitis = excluded.bitis;

select u.email, p.paket, p.bitis
  from paket_uyeler p join auth.users u on u.id = p.user_id
 where u.email = 'inceleme@tetikte.com';
