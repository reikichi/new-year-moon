require 'time'
require 'mk_time'
require 'eph_jpl'

# JPLのデータ
$data_path = 'ssd.jpl.nasa.gov/pub/eph/planets/Linux/de430/linux_p1550p2650.430'

$pi57 = 180.0 / Math::PI
$pi2 = 2.0 * Math::PI

def ephXyz(target, time)
  # target: sun / moon
  # time: UTC DateTime型
  ttjd = MkTime::Calc.new(MkTime::Calc.new(time).tt).jd # UTCをTTに変換したユリウス日
  if target == :sun
    target_id = 11
  elsif target == :moon
    target_id = 10
  else
    raise
  end
  ephJpl = EphJpl.new($data_path, target_id, 3, ttjd)
  value = ephJpl.calc
  x = value[0]
  y = value[1]
  z = value[2]
  return [x, y, z]
end

def xyzEquatorialToEcliptic(xyz)
  # 地球の黄道傾斜角で座標を回転
  # バイアス・歳差・章動は考慮していない
  return rotationX(xyz, -0.4090926)
end

def rotationX(xyz, th)
  # X軸を中心に位置を反時計回りに回転
  x = xyz[0]
  y = xyz[1]
  z = xyz[2]
  cos = Math.cos(th)
  sin = Math.sin(th)
  return [x, y * cos - z * sin, y * sin + z * cos]
end

# 計算する期間
startYear = 1970
startYear.upto(2050) do |year|
  startTime = Time.parse("#{year}-01-01T00:00:00.000+09:00")
  endTime = Time.parse("#{year}-01-02T00:00:00.000+09:00")

  time = startTime
  moonSunLng = nil

  # 1時間ごとに月と太陽の黄経差を計算
  while time < endTime
    sun = xyzEquatorialToEcliptic(ephXyz(:sun, time))
    moon = xyzEquatorialToEcliptic(ephXyz(:moon, time))

    # 黄経を計算
    sunLng = Math.atan2(sun[1], sun[0]);
    moonLng = Math.atan2(moon[1], moon[0]);

    # 黄経差を計算
    moonSunLng2 = moonLng - sunLng
    moonSunLng2 += $pi2 if (moonSunLng2 < 0)
    moonSunLng2 *= $pi57

    if moonSunLng != nil
      # 新月の時刻を線形補間で計算
      if moonSunLng > 270 && moonSunLng2 < 90
        t = time - moonSunLng2 / (moonSunLng2 - moonSunLng + 360) * 3600
        puts("#{t} 新月")
      end
    end

    moonSunLng = moonSunLng2

    time = time + 3600
  end
end
