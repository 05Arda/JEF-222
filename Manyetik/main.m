%% Parametreler

filename = 'Manyetik/manyetik_data.xlsx';
data = readtable(filename);

stations = string(data{:, 1});
deltaX = data{:, 2};
timeStr = string(data{:, 3});
measures = data{:, 4};

% MATLAB'ın saat hesaplaması yapabilmesi için noktaları iki noktaya çeviriyoruz
timeStr = strrep(timeStr, '.', ':');
times = datetime(timeStr, 'InputFormat', 'HH:mm:ss');

% Baz ve Profil indexlerini ayırma
idxBase = contains(stations, 'Baz', 'IgnoreCase', true);
idxProfile = contains(stations, 'Profil', 'IgnoreCase', true);

basetimes = times(idxBase);
baseMeasures = measures(idxBase);

figure(1)
plot(basetimes, baseMeasures);
grid on;
hold on;

profiletimes = times(idxProfile);
profileMeasures = measures(idxProfile);
profileNames= stations(idxProfile);
profiledeltaX = deltaX(idxProfile); % Ölçüm alınan metre 0-30



numProfiles = 7;
numMeters = 31; % 0'dan 30'a kadar 31 nokta
profileRange = 1; % Profiller arası mesafe (metre).


%% Günlük Değişim (Diurnal) Düzeltmesi

% Profil ölçümlerinin yapıldığı saatlerdeki teorik Baz değerlerini
% interpolasyon yardımıyla hesaplıyoruz
interpolatedBase = interp1(basetimes, baseMeasures, profiletimes, 'spline', 'extrap');
plot(profiletimes, interpolatedBase)
legend("Baz Ölçümleri (Ham)", "Baz Ölçümleri (Interpolated)")

% Delta T_diurnal = T_obs - (T_base - T_mean)
% omitnan -> omit nan (NaN değerlerini çıkartarak ortalama hesaplar)
tMean = mean(baseMeasures, 'omitnan');
tDiurnal = profileMeasures - interpolatedBase + tMean;


%% IGRF Düzeltmesi
IGRF_F = 48450.5;       % Total Intensity (Bunu web sitesinden tekrar kontrol edin)
IGRF_D = 6.16282;       % Declination (Sapma)
IGRF_I = 58.5;          % Inclination (Eğim - Bunu da web sitesinden alın)

% 1. Adım: Baz Düzeltmesi (Önce bunu yapmalısınız)
% mag_clean = raw_data - (baz_data - baz_referans);

% 2. Adım: IGRF Düzeltmesi
magnetic_anomaly = mag_clean - IGRF_F;

%%

% 5. 2D MATRİS (GRID) OLUŞTURMA


% X (Hat Uzunluğu) ve Y (Profiller Arası Genişlik) eksenlerini oluştur
X = 0:1:30;
Y = (0:numProfiles-1) * profileRange;
[X_grid, Y_grid] = meshgrid(X, Y);
Z_grid = NaN(numProfiles, numMeters);

% Düzeltilmiş verileri 7x31'lik matrise yerleştir
for i = 1:length(duzeltilmisOlcum)
    p_isim = profileNames(i);
    m = profiledeltaX(i);

    % Profil numarasını isminden otomatik çıkar ('1. Profil' -> 1)
    p_num = sscanf(p_isim, '%d');

    if ~isnan(m) && m >= 0 && m <= 30
        Z_grid(p_num, m + 1) = duzeltilmisOlcum(i);
    end
end

% Eksik veriyi doldurma (Örn: 7. Profilin 6. metresindeki boşluk)
% 'linear' interpolasyon ile komşu değerlere bakarak boşluğu doldurur
Z_grid = fillmissing(Z_grid, 'linear', 2);

% 6. 2D ANOMALİ HARİTASI ÇİZİMİ
figure('Name', 'Manyetik Anomali Haritası', 'Color', 'w', 'Position', [100, 100, 900, 500]);

% Yüksek çözünürlüklü kontur haritası
contourf(X_grid, Y_grid, Z_grid, 50, 'LineStyle', 'none');
hold on;

% Gerçek ölçüm noktalarını soluk siyah noktalarla göster (Grid kontrolü için)
scatter(X_grid(:), Y_grid(:), 10, 'k', 'filled', 'MarkerFaceAlpha', 0.2);

% Görsel Ayarlar
colormap('jet'); % Jeofizikte klasik mavi-kırmızı renk paleti
c = colorbar;
c.Label.String = 'Düzeltilmiş Manyetik Alan (nT)';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';

title('Diurnal Düzeltmesi Yapılmış 2D Manyetik Anomali Haritası', 'FontSize', 14);
xlabel('Hat Uzunluğu (Metre)', 'FontSize', 12);
ylabel('Profil Mesafesi (Metre)', 'FontSize', 12);
axis equal tight; % Orantılı görünüm