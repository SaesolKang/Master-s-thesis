clear
set more off


use "2010farm.dta", replace
use "estimation2010(0625).dta", replace


*시군구 생성
tostring v2, replace
replace v2="0"+v2 if strlen(v2)==2
egen 시군구=concat(v1 v2)
egen 읍면동=concat(v1 v2 v3)

rename v43 auto
rename v44 ordinary
gen glass=v45
gen mushroom=v46
gen etc=v47

*집단 3개로 구분(auto, ordinary only, the others)
gen category2=0
replace category2=1 if auto>0 
replace category2=2 if auto==0 & ordinary>0

bys 시군구: egen AG_N=total(auto>0)
bys 읍면동: egen AG_N2=total(auto>0)
bys 시군구: gen totalfarm_N=_N
bys 읍면동: gen totalfarm_N2=_N
gen AG_IN_TOWN=AG_N/totalfarm_N
gen AG_IN_TOWN2=AG_N2/totalfarm_N2

drop if v5==.
gen auto_m=auto*10000
replace auto_m=1 if auto_m==0
gen lnauto_m=ln(auto_m)
rename v8 exp

*축산 농가 제외
drop if v104==17

*토지가 0인 농가 제외
gen land=v19+v25
drop if land==0

*시설면적이 양수인 농가
keep if v42==1

*판매목적 시설 작물 재배 농가
keep if v49==1

merge m:1 읍면동 using "읍면동거리2010.dta", gen(_merge2)
drop if _merge2==2
gen 읍면동거리km=읍면동거리2/1000

merge m:1 시군구 using "minimum_distance(2010).dta", gen(_merge3)
drop if v3==.


*가구원
drop if v5==.
rename v7 age
rename v14 owner
rename v15 edu
recode v16 (1=3) (4=2) (5=1) , gen(level)
gen age2=age^2
sort v4
bys v4: egen adultnumber=count(age>=19)

*가구원 데이터 머징
merge 1:m v4 using farm_hhm2010.dta, keep(match) nogenerate force
keep if owner==1


*age
gen elder=(age>=65)
gen age_twentiesthirties=(age>=20 & age<40)
gen age_forties=(age>=40 & age<50)
gen age_sixtyfour=(age>=50 & age<=64)
gen age_oversixtyfour=elder

*edu를 구분해보자(고졸미만/고졸/대졸) (무학/고졸미만/고졸/2년대졸/4년대졸)
gen overhigh=(high_grad==1 | bachelor==1 )

*고졸 미만 (초중졸과 고졸 미만의 평균 임금이 소수점 한 자리까지 유사해서 합침)
gen under_high=0
replace under_high=1 if edu==1
replace under_high=1 if edu==2
replace under_high=1 if edu==3 
replace under_high=1 if edu==4 & level==1
replace under_high=1 if edu==4 & level==2

*고졸(2년제 재학과 4년제 재학을 포함)
gen high_grad=0
replace high_grad=1 if edu==4 & level==3
replace high_grad=1 if edu==5 & level==1 | edu==5 & level==2
replace high_grad=1 if edu==6 & level==1 | edu==6 & level==2

*2년제
gen college=0
replace college=1 if edu==5 & level==3

*4년대졸 
gen university=0
replace university=1 if edu==6 & level==3
replace university=1 if edu==7 | edu==8

*대졸
gen bachelor=0
replace bachelor=1 if edu==5 & level==3
replace bachelor=1 if edu==6 & level==3
replace bachelor=1 if edu==7 
replace bachelor=1 if edu==8 

*대학원졸
gen graduate=0
replace graduate=1 if edu==7 & level==3
replace graduate=1 if edu==8 

*school->year(무학은 0, 초등학교 재학, 휴학, 중퇴는 3, 졸업, 수료는 6, 중학교 재학휴학중퇴는 7.5, 졸업수료는 9, 고등학교 재학휴학중퇴는 10.5, 졸업수료는 12, 대학교 4년제 미만 재학휴학중퇴는 13, 졸업수료는 14, 4년제대학 재학휴학 중퇴는 14, 졸업수료는 16)
gen schyear=0 if edu==1
replace schyear=3 if (edu==2 & level==1) | (edu==2 & level==2)
replace schyear=6 if edu==2 & level==3
replace schyear=7.5 if (edu==3 & level==1) | (edu==3 & level==2)
replace schyear=9 if edu==3 & level==3
replace schyear=10.5 if (edu==4 & level==1) | (edu==4 & level==2)
replace schyear=12 if edu==4 & level==3
replace schyear=13 if (edu==5 & level==1) | (edu==5 & level==2)
replace schyear=14 if edu==5 & level==3 | (edu==6 & level<3)
replace schyear=16 if edu==6 & level==3
replace schyear=17 if edu==7 & level<3
replace schyear=18 if edu==7 & level==3
replace schyear=21 if edu==8 & level<3
replace schyear=24 if edu==8 & level==3

*2015머징용(대학원 구분 안함)
gen schyear=0 if edu==1
replace schyear=3 if (edu==2 & level==1) | (edu==2 & level==2)
replace schyear=6 if edu==2 & level==3
replace schyear=7.5 if (edu==3 & level==1) | (edu==3 & level==2)
replace schyear=9 if edu==3 & level==3
replace schyear=10.5 if (edu==4 & level==1) | (edu==4 & level==2)
replace schyear=12 if edu==4 & level==3
replace schyear=13 if (edu==5 & level==1) | (edu==5 & level==2)
replace schyear=14 if edu==5 & level==3 | (edu==6 & level<3)
replace schyear=16 if edu==6 & level==3 | edu>=7

*전업 및 겸업
rename v143 farmtype
label define farmtype 1 "farm_only" 2 "more_farm" 3 "more_others"
label value farmtype farmtype
numlabel _all, add 
tab farmtype, gen(farmtypedummy)
gen 농업수입뿐임=farmtypedummy1
gen 농업수입이많음=farmtypedummy2


*Sales channel
gen sales_channel=v107
gen 농협=sales_channel==3
gen 친환경=sales_channel==6
gen 가공업체=sales_channel==8
gen 기타대형유통업체=sales_channel==10 & Sales>0
gen 직거래=(sales_channel==7)
gen 도매시장공판장=(sales_channel<3)
gen 전자상거래=(직거래==1 & v147==1)
/// v38로 표본을 좁혔을 때만 사용가능
label define sales_channel 1 "도매시장" 2 "산지공판장" 3 "농협농업법인" 4 "정부기관공공비축제등" 5 "수집상중간상인밭떼기등" 6 "친환경농산물전문유통업체생협포함" 7 "소비자직접판매" 8 "농축산물가공업체" 9 "농축산물소매상" 10 "기타판매없음포함", replace
label value sales_channel sales_channel
numlabel _all, add

*sales 변형
gen sales=v103
gen Sales=1 if sales<6
replace Sales=0 if sales==1
replace Sales=2 if sales>=6 & sales<9
replace Sales=3 if sales==9 
replace Sales=4 if sales>=10 
tab Sales, gen(salesdummy)
label define Sales 0 "판매없음" 1 "천만미만" 2 "천만이상오천미만" 3 "오천이상일억미만" 4 "일억이상"
label value Sales Sales
numlabel _all, add
gen 천만이상오천미만=salesdummy2
gen 오천이상일억미만=salesdummy3
gen 일억이상=salesdummy4

*생산자 조직 참여
*1. 법인만
gen corporation=0
replace corporation=1 if v114==1 | v115==1 | v116==1

*2. 작목반만 (논벼 작목반, 기타 작목반 제외)
gen cooperative=0
replace cooperative=1 if v109==1 | v110==1 | v111==1 | v112==1 
label variable v109 "채소산나물작목반"
label variable v110 "특용약용작목반"
label variable v111 "화초관상작목반"
label variable v112 "과수작목반"
gen 채소산나물작목반=v109
gen 특용약용작목반=v110
gen 화초관상작목반=v111
gen 과수작목반=v112

*employment(significant하면 변수를 추가하자)
recode v125 (1=1) (2=0), gen(emp)

*Land in ownership(시설작물은 자가 확인 불가)
gen own=v12+v21
gen ownland=own/land
gen Own=(ownland==1)

*Size of Greenhouse (판매금액 넣으면 이것 빼야함)
gen house_size=v48
gen total_land=land

*proportion of greenhouse
*gen house_proportion=house_size/total_land


*rural(11-15:읍 21-47:면 51-91:동)
gen rural=(v3<50)

*discordance: 영농지역 변수 없음

*use of IT devices: 컴퓨터밖에 없음. 자동화 목적도 없음.
gen ITgeneral=(v145==1)

*region
gen province =v1
gen region=0
replace region=1 if province==11 | province==23 | province==31
replace region=2 if province==32
replace region=3 if province==25 | province==33 | province==34
replace region=4 if province==24 | province==35 | province==36
replace region=5 if province==21 | province==22 | province==26 | province==37 | province==38
replace region=6 if province==39
label define region 1 "Gyeonggi" 2 "Gangwon" 3 "Chungcheong" 4 "Jeolla" 5 "Gyeongsang" 6 "Jeju" 
label value region region
numlabel _all, add 
tab region, gen(regiondummy)
label variable regiondummy1 "경기" 
label variable regiondummy2 "강원" 
label variable regiondummy3 "충청" 
label variable regiondummy4 "전라" 
label variable regiondummy5 "경상" 
label variable regiondummy6 "제주"
gen 경기=regiondummy1
gen 강원=regiondummy2
gen 충청=regiondummy3
gen 전라=regiondummy4
gen 경상=regiondummy5
gen 제주=regiondummy6


*작물 데이터 머징
drop if v5==.
rename v5 cardnumber
rename v6 crop
rename v7 area
rename v8 area2
rename v9 재배방법
rename v10 친환경유무


sort v4

merge 1:m v4 using "2010farmcrop.dta", keep(match) gen(_merge1) force

label define crop 02010100	"배추" ///
02010200	"무" ///
02010300	"고추" ///
02010400	"시금치" ///
02010500	"상추" /// 
02010600	"호박" /// 
02010700	"오이" ///
02010800	"수박" ///
02010900	"토마토" ///
02011000	"딸기" ///
02011100	"참외" ///
02011200	"서양채소" ///
02020100	"화초작물(꽃)" ///
02030200	"관상작물" ///
02040100	"톱밥배지(봉수)" ///
02040200	"원목재배(본수)" ///
02050100	"기타버섯" ///
02060200	"기타시설작물" ///
02070100	"산나물" ///
02080100	"약용작물" ///
04020100	"가시오가피(시설)" ///
04020200	"가지(시설)" ///
04020300	"고구마순(시설)" ///
04020400	"곤달비(시설)" ///
04020500	"곰취(시설)" ///
04020600	"구아바(시설)" ///
04020700	"국화(시설)" ///
04020800	"느타리버섯(시설)" ///
04020900	"달래(시설)" ///
04021000	"들깻잎(시설)" ///
04021100	"망고(시설)" ///
04021200	"머위(시설)" ///
04021300	"멜론(시설)" /// 
04021400	"미나리(시설)" ///
04021500	"방울토마토(시설)" ///
04021600	"백합(시설)" ///
04021700	"복분자(시설)" ///
04021800	"부추(시설)" ///
04021900	"브로콜리(시설)" ///
04022000	"블루베리(시설)" /// 
04022100	"새송이버섯(시설)" ///
04022200	"선인장(시설)" ///
04022300	"쑥갓(시설)" ///
04022400	"아스파라거스(시설)" ///
04022500	"알로에(시설)" ///
04022600	"애호박(시설)" ///
04022700	"양란(시설)" ///
04022800	"양송이(시설)" ///
04022900	"얼갈이(시설)" ///
04023000	"열무(시설)" ///
04023100	"오미자(시설)" ///
04023200	"장미(시설)" /// 
04023300	"쪽파(시설)" ///
04023400	"참나물(시설)" ///
04023500	"참다래(시설)" /// 
04023600	"참취나물(시설)" ///
04023700	"천마(시설)" ///
04023800	"청경채(시설)" ///
04023900	"취나물(시설)" ///
04024000	"파프리카(시설)" ///
04024100	"풋고추(시설)" ///
04024200	"피망(시설)" ///
04024300	"한라봉(시설)" ///
04030100	"울외(노지,시설)" ///
04030200	"블루베리(시설,노지)" ///
04040100	"묘목(조경수,과수)" ///
03021100 "기타시설과수" ///
5010200 "친환경채소", replace
destring crop, replace force
label value crop* crop
numlabel _all, add 


*시군구작물 
gen towncrop=(crop>=4020100 & crop<=4040100)
bys v4: egen towncroparea=total(area) if towncrop==1
bys v4: egen 시군구토마토=total(area) if crop==4021500 
bys v4: egen 시군구파프리카=total(area) if crop==4024000
bys v4: egen 시군구멜론=total(area) if crop==4021300
bys v4: egen 시군구장미=total(area) if crop==4023200
bys v4: egen 시군구양란=total(area) if crop==4022700
bys v4: egen 시군구버섯=total(area) if crop==4020800 | crop==4022100 | crop==4022800 
bys v4: egen 시군구국화=total(area) if crop==4020700

*정책작물
bys v4: gen 오이=area if crop==2010700
bys v4: gen 수박=area if crop==2010800
bys v4: gen 토마토=area if crop==2010900
bys v4: gen 딸기=area if crop==2011000
bys v4: gen 참외=area if crop==2011100
bys v4: gen 파프리카포함서양채소=area if crop==2011200
bys v4: gen 장미국화포함꽃=area if crop==2020100
bys v4: gen 멜론포함기타시설작물=area if crop==2060200
bys v4: egen 버섯류=total(area) if crop==2040100 | crop==2040200 | crop==2050100 

*egen total로 하면 같은 가구 내에서 시군구 작물을 기르는 데이터 옆에만 towncrop이 생성됨. egen max gogo
egen towncroparea_=max(towncroparea), by(v4)
egen 시군구토마토_=max(시군구토마토), by(v4)
egen 시군구파프리카_=max(시군구파프리카), by(v4)
egen 시군구멜론_=max(시군구멜론), by(v4)
egen 시군구장미_=max(시군구장미), by(v4)
egen 시군구양란_=max(시군구양란), by(v4)
egen 시군구버섯_=max(시군구버섯), by(v4)
egen 시군구국화_=max(시군구국화), by(v4)

egen 오이_=max(오이), by(v4) 
egen 수박_=max(수박), by(v4) 
egen 토마토_=max(토마토), by(v4) 
egen 딸기_=max(딸기), by(v4) 
egen 참외_=max(참외), by(v4) 
egen 파프리카포함서양채소_=max(파프리카포함서양채소), by(v4) 
egen 장미국화포함꽃_=max(장미국화포함꽃), by(v4) 
egen 멜론포함기타시설작물_=max(멜론포함기타시설작물), by(v4) 
egen 버섯류_=max(버섯류), by(v4)

replace towncroparea_=0 if towncroparea_==.
replace 시군구토마토_=0 if 시군구토마토_==.
replace 시군구파프리카_=0 if 시군구파프리카_==.
replace 시군구멜론_=0 if 시군구멜론_==.
replace 시군구장미_=0 if 시군구장미_==.
replace 시군구양란_=0 if 시군구양란_==.
replace 시군구버섯_=0 if 시군구버섯_==.
replace 시군구국화_=0 if 시군구국화_==.

replace 오이_=0 if 오이_==.
replace 수박_=0 if 수박_==.
replace 토마토_=0 if 토마토_==.
replace 딸기_=0 if 딸기_==.
replace 참외_=0 if 참외_==.
replace 파프리카포함서양채소_=0 if 파프리카포함서양채소_==.
replace 장미국화포함꽃_=0 if 장미국화포함꽃_==.
replace 멜론포함기타시설작물_=0 if 멜론포함기타시설작물_==.
replace 버섯류_=0 if 버섯류_==.

gen 정책작물=오이_+수박_+토마토_+딸기_+참외_+파프리카포함서양채소_+장미국화포함꽃_+멜론포함기타시설작물_

bys v4: egen towncropnumber=count(towncrop) if towncrop==1
replace towncropnumber=0 if towncropnumber==.
egen towncropnumber_=max(towncropnumber), by(v4)

bys v4: gen cropnumber=_N
bys v4: gen croporder=_n

gsort v4 -area
order v4 area
drop cardnumber towncrop towncropnumber area2  _merge* 재배방법 ///
친환경유무 towncroparea 시군구토마토 시군구파프리카 시군구멜론 시군구장미 시군구양란 시군구버섯 ///
시군구국화 오이 수박 토마토 딸기 참외 파프리카포함서양채소 장미국화포함꽃 멜론포함기타시설작물 버섯류 

*이유는 모르겠는데 reshape하면 관측치가 1개 사라진다.
reshape wide crop area, i(v4) j(croporder)
forvalues i=1/36 {
replace area`i'=0 if area`i'==.
}
egen 재배면적=rowtotal(area*), missing
egen 재배면적2=rowtotal(area*)
forvalues i=1/36 {
replace 재배면적2=재배면적2-area`i' if crop`i'>4010000 & crop`i'<4040200
}

gen towncrop_proportion=towncroparea/재배면적2
replace towncrop_proportion=0 if towncrop_proportion==.
gen 시군구토마토비율=시군구토마토_/재배면적2
gen 시군구파프리카비율=시군구파프리카_/재배면적2
gen 시군구멜론비율=시군구멜론_/재배면적2
gen 시군구장미비율=시군구장미_/재배면적2
gen 시군구양란비율=시군구양란_/재배면적2
gen 시군구버섯비율=시군구버섯_/재배면적2
gen 시군구국화비율=시군구국화_/재배면적2
gen 시군구정책작물비율=시군구토마토비율+시군구파프리카비율+시군구멜론비율+시군구장미비율+시군구양란비율

gen 오이비율=오이/재배면적2
gen 수박비율=수박/재배면적2
gen 토마토비율=토마토/재배면적2
gen 딸기비율=딸기/재배면적2
gen 참외비율=참외/재배면적2
gen 파프리카포함서양채소비율=파프리카포함서양채소/재배면적2
gen 장미국화포함꽃비율=장미국화포함꽃/재배면적2
gen 멜론포함기타시설작물비율=멜론포함기타시설작물/재배면적2
gen 버섯류비율=버섯류_/재배면적2
gen 정책작물비율=정책작물/재배면적2

*경력의 categorization(2년 이하는 low, 2년 초과, 10년 미만은 middle, 10년 이상은 high)
gen exp_category=0
replace exp_category=1 if exp<=2
replace exp_category=2 if exp>2 & exp<10
replace exp_category=3 if exp>=10


*dependent variable
gen AG_GREEN=auto/house_size

gen total_land_m=10000*total_land
gen lntotal_land=log(total_land_m)
gen lntotal_land2=lntotal_land^2

rename v104 mainincome
label define mainincome 1 "논벼(노지)" 2 "논벼(시설)" 3 "식량작물(노지)" 4 "식량작물(시설)" 5 "채소산나물(노지)" 6 "채소산나물(시설)" ///
7 "특용작물버섯(노지)" 8 "특용작물버섯(시설)" 9 "과수(노지)" 10 "과수(시설)" 11 "약용작물(노지)" 12 "약용작물(시설)" 13 "화초관상작물(노지)" ///
14 "화초관상작물(시설)" 15 "기타작물(노지)" 16 "기타작물(시설)" 17 "축산"
label value mainincome mainincome
numlabel _all, add 
*짝수표기
gen byte even=~mod(mainincome,2)

tab mainincome, gen(mainincomedummy)
gen 논벼_노지=mainincomedummy1 
gen 식량작물_노지=mainincomedummy2 
gen 식량작물_시설=mainincomedummy3 
gen 채소산나물_노지=mainincomedummy4 
gen 채소산나물_시설= mainincomedummy5
gen 특용작물버섯_노지= mainincomedummy6
gen 특용작물버섯_시설= mainincomedummy7
gen 과수_노지= mainincomedummy8
gen 과수_시설= mainincomedummy9
gen 약용작물_노지= mainincomedummy10
gen 약용작물_시설= mainincomedummy11
gen 화초관상작물_노지= mainincomedummy12
gen 화초관상작물_시설= mainincomedummy13
gen 기타작물_노지= mainincomedummy14
gen 기타작물_시설= mainincomedummy15


*시설 노지 합치기
gen 논벼=논벼_노지
gen 식량작물=(식량작물_노지==1 | 식량작물_시설==1)
gen 채소산나물=(채소산나물_노지==1 | 채소산나물_시설==1)
gen 특용작물버섯=(특용작물버섯_노지==1 | 특용작물버섯_시설==1)
gen 과수=(과수_노지==1 | 과수_시설==1)
gen 약용작물=(약용작물_노지==1 | 약용작물_시설==1)
gen 화초관상작물=(화초관상작물_노지==1 | 화초관상작물_시설==1)
gen 기타작물=(기타작물_노지==1 | 기타작물_시설==1)
gen 주소득시설=(식량작물_시설==1 | 채소산나물_시설==1 | 특용작물버섯_시설==1 | 과수_시설==1 | 약용작물_시설==1 | 화초관상작물_시설==1 | 기타작물_시설==1)

gen machinery=(v134==1)




gen 농업뿐or농업수입이많음=(farmtypedummy1==1 | farmtypedummy2==1)
gen year2015=0
*자동화 비닐하우스 면적 4분위로 나눔. 1이 최하위 25% 그룹
xtile auto_4=auto if auto>0, nquantiles(4)

*최대면적 작물
bys v4: gen 최대면적작물1=crop1 
bys v4: gen 최대면적작물2=crop2 if area1==area2 
bys v4: gen 최대면적작물3=crop3 if area1==area2 & area2==area3
bys v4: gen 최대면적작물4=crop4 if area1==area2 & area2==area3 & area3==area4

egen biggestarea=rowmax(area*)
gen biggestcrop=crop1 if area1==biggestarea
forvalues i=1/36 {
replace biggestcrop=crop`i' if area`i'==biggestarea
}
label value biggestcrop crop

tabstat lnauto autoYes age* exp under_high high_grad bachelor ITgeneral towncrop_prop sales_channel house_proportion ///
ownland cropnumber corporation cooperative farmdummy* adultnumber emp lntotal_land machinery minimum_distance AG_GREEN ///
경기 강원 충청 전라 경상 제주 논벼 식량작물 채소산나물 특용작물버섯 과수 약용작물 화초관상작물 기타작물, ///
statistics(mean sd median count) varwidth(32) c(s) longstub 

*시군구작물을 기르면 면적이 작은게 아닐까?
forvalues i=1/36 {
su area`i' if crop`i'<4030300 & crop`i'>4020000 & crop`i'!=.
}

  churdle linear lnauto ITgeneral age_twenties age_sixtyfour age_oversixtyfour ///
 exp  exp2  ///
  schyear 친환경  ///
 ownland cropnumber corporation ///
 cooperative 농업수입뿐임 농업수입이많음 adultnumber emp  ///
 lntotal_land lntotal_land2 읍면동거리km  AG_IN_TOWN2  ///
강원 충청 전라 경상 제주 정책작물비율 , ///
select( ITgeneral age_twenties age_sixtyfour age_oversixtyfour ///
exp exp2  ///
schyear 친환경 ownland cropnumber corporation ///
 cooperative 농업수입뿐임 농업수입이많음 adultnumber emp lntotal_land ///
  lntotal_land2 읍면동거리km  AG_IN_TOWN2  ///
강원 충청 전라 경상 제주 정책작물비율 ) ll(0) vce(robust) 
estimate store msquare
estout msquare, cell( b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
starlevels(* 0.1 ** 0.05) legend varwidth(25)
*exp의 극점
di -_b[exp]/(2*_b[exp2])

churdle linear lnauto  age_sixtyfour age_oversixtyfour ///
 exp  exp2 ITgeneral  ///
  high_grad bachelor 농협 친환경 기타대형유통업체 직거래 도매시장공판장   ///
 ownland cropnumber corporation ///
 cooperative 농업수입뿐임 농업수입이많음 adultnumber emp  ///
 lntotal_land lntotal_land2 읍면동거리km rural AG_IN_TOWN2  ///
정책작물비율  ///
강원 충청 전라 경상 제주  , ///
select(  age_sixtyfour age_oversixtyfour ///
exp exp2 ITgeneral  ///
high_grad bachelor 농협 친환경 기타대형유통업체 직거래 도매시장공판장  ownland cropnumber corporation ///
 cooperative 농업수입뿐임 농업수입이많음 adultnumber emp lntotal_land ///
  lntotal_land2 읍면동거리km rural AG_IN_TOWN2  ///
정책작물비율 ///
강원 충청 전라 경상 제주 ) ll(0) vce(robust) 
estimate store msquare
estout msquare, cell( b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
starlevels(* 0.1 ** 0.05 *** 0.01) legend varwidth(25)

*1-1. two-limit tobit
qui xi: tobit AG_GREEN age_forty age_sixtyfour age_oversixtyfour exp exp2 high_grad bachelor ITgeneral towncrop_proportion ///
 sales_channel house_proportion ownland cropnumber corporation cooperative adultnumber emp total_land machinery  ///
 농업수입뿐임 농업수입이많음 rural minimum_distance AG_IN_TOWN 강원 충청 전라 경상 제주 식량작물 채소산나물 특용작물버섯 과수 약용작물 화초관상작물 기타작물, ll(0) ul(1) vce(robust) 
estimate store twolimittobit
estout twolimittobit, cell(b(star fmt(%9.3f)) se(par fmt(%9.3f))) starlevels(* 0.1 ** 0.05 *** 0.01) legend 

*1-2. tobit
tobit lnauto_m age age2 i.exp_category high_grad bachelor graduate ITgeneral towncroparea ///
 sales_channel house_proportion ownland cropnumber corporation cooperative adultnumber emp lntotal_land machinery  ///
 농업수입뿐임 농업수입이많음 minimum_distance AG_in_town 강원 충청 전라 경상 제주 식량작물 채소산나물 특용작물버섯 과수 약용작물 화초관상작물 기타작물 , ll(0)  vce(robust) 
estimate store tobit
estout tobit, cell(b(star fmt(%9.3f)) se(par fmt(%9.3f))) starlevels(* 0.1 ** 0.05 *** 0.01) legend 


*hurdle model
churdle linear lnauto_m age_twentiesthirties age_sixtyfour age_oversixtyfour exp  high_grad bachelor ITgeneral ///
towncrop_proportion sales_channel house_proportion ownland cropnumber corporation cooperative 농업수입뿐임 농업수입이많음 adultnumber emp machinery ///
  minimum_distance AG_IN_TOWN 강원 충청 전라 경상 제주 식량작물 채소산나물 특용작물버섯 과수 약용작물 화초관상작물 기타작물 , ///
select(age_twentiesthirties age_sixtyfour age_oversixtyfour exp high_grad bachelor ITgeneral  ///
towncrop_proportion sales_channel house_proportion ownland cropnumber corporation cooperative adultnumber emp lntotal_land  machinery ///
 농업수입뿐임 농업수입이많음 minimum_distance AG_IN_TOWN 강원 충청 전라 경상 제주 식량작물 채소산나물 특용작물버섯 과수 약용작물 화초관상작물 기타작물) ll(0) vce(robust) 
estimate store msquare
estout msquare, cell( b(star fmt(%9.3f)) se(par fmt(%9.3f))) starlevels(* 0.1 ** 0.05) legend varwidth(25)


 *기초통계량
 egen autoTotal=total(auto)
 egen houseTotal=total(house_size)
xtile AG_GREEN4=AG_GREEN , nquantiles(4)
destring 시군구, gen(shigungu) force
label define 시군구 ///
11010	"종로구"	///
11020	"중구"	///
11030	"용산구"	///
11040	"성동구"	///
11050	"광진구"	///
11060	"동대문구"	///
11070	"중랑구"	///
11080	"성북구"	///
11090	"강북구"	///
11100	"도봉구"	///
11110	"노원구"	///
11120	"은평구"	///
11130	"서대문구"	///
11140	"마포구"	///
11150	"양천구"	///
11160	"강서구"	///
11170	"구로구"	///
11180	"금천구"	///
11190	"영등포구"	///
11200	"동작구"	///
11210	"관악구"	///
11220	"서초구"	///
11230	"강남구"	///
11240	"송파구"	///
11250	"강동구"	///
21010	"중구"	///
21020	"서구"	///
21030	"동구"	///
21040	"영도구"	///
21050	"부산진구"	///
21060	"동래구"	///
21070	"남구"	///
21080	"북구"	///
21090	"해운대구"	///
21100	"사하구"	///
21110	"금정구"	///
21120	"강서구"	///
21130	"연제구"	///
21140	"수영구"	///
21150	"사상구"	///
21310	"기장군"	///
22010	"중구"	///
22020	"동구"	///
22030	"서구"	///
22040	"남구"	///
22050	"북구"	///
22060	"수성구"	///
22070	"달서구"	///
22310	"달성군"	///
23010	"중구"	///
23020	"동구"	///
23030	"남구"	///
23040	"연수구"	///
23050	"남동구"	///
23060	"부평구"	///
23070	"계양구"	///
23080	"서구"	///
23310	"강화군"	///
23320	"옹진군"	///
24010	"동구"	///
24020	"서구"	///
24030	"남구"	///
24040	"북구"	///
24050	"광산구"	///
25010	"동구"	///
25020	"중구"	///
25030	"서구"	///
25040	"유성구"	///
25050	"대덕구"	///
26010	"중구"	///
26020	"남구"	///
26030	"동구"	///
26040	"북구"	///
26310	"울주군"	///
29010	"세종시"	///
31010	"수원시"	///
31011	"수원시 장안구"	///
31012	"수원시 권선구"	///
31013	"수원시 팔달구"	///
31014	"수원시 영통구"	///
31020	"성남시"	///
31021	"성남시 수정구"	///
31022	"성남시 중원구"	///
31023	"성남시 분당구"	///
31030	"의정부시"	///
31040	"안양시"	///
31041	"안양시 만안구"	///
31042	"안양시 동안구"	///
31050	"부천시"	///
31051	"부천시 원미구"	///
31052	"부천시 소사구"	///
31053	"부천시 오정구"	///
31060	"광명시"	///
31070	"평택시"	///
31080	"동두천시"	///
31090	"안산시"	///
31091	"안산시 상록구"	///
31092	"안산시 단원구"	///
31100	"고양시"	///
31101	"고양시 덕양구"	///
31103	"고양시 일산동구"	///
31104	"고양시 일산서구"	///
31110	"과천시"	///
31120	"구리시"	///
31130	"남양주시"	///
31140	"오산시"	///
31150	"시흥시"	///
31160	"군포시"	///
31170	"의왕시"	///
31180	"하남시"	///
31190	"용인시"	///
31191	"용인시 처인구"	///
31192	"용인시 기흥구"	///
31193	"용인시 수지구"	///
31200	"파주시"	///
31210	"이천시"	///
31220	"안성시"	///
31230	"김포시"	///
31240	"화성시"	///
31250	"광주시"	///
31260	"양주시"	///
31270	"포천시"	///
31280	"여주시"	///
31350	"연천군"	///
31370	"가평군"	///
31380	"양평군"	///
32010	"춘천시"	///
32020	"원주시"	///
32030	"강릉시"	///
32040	"동해시"	///
32050	"태백시"	///
32060	"속초시"	///
32070	"삼척시"	///
32310	"홍천군"	///
32320	"횡성군"	///
32330	"영월군"	///
32340	"평창군"	///
32350	"정선군"	///
32360	"철원군"	///
32370	"화천군"	///
32380	"양구군"	///
32390	"인제군"	///
32400	"고성군"	///
32410	"양양군"	///
33020	"충주시"	///
33030	"제천시"	///
33040	"청주시"	///
33041	"청주시 상당구"	///
33042	"청주시 서원구"	///
33043	"청주시 흥덕구"	///
33044	"청주시 청원구"	///
33320	"보은군"	///
33330	"옥천군"	///
33340	"영동군"	///
33350	"진천군"	///
33360	"괴산군"	///
33370	"음성군"	///
33380	"단양군"	///
33390	"증평군"	///
34010	"천안시"	///
34011	"천안시 동남구"	///
34012	"천안시 서북구"	///
34020	"공주시"	///
34030	"보령시"	///
34040	"아산시"	///
34050	"서산시"	///
34060	"논산시"	///
34070	"계룡시"	///
34080	"당진시"	///
34310	"금산군"	///
34330	"부여군"	///
34340	"서천군"	///
34350	"청양군"	///
34360	"홍성군"	///
34370	"예산군"	///
34380	"태안군"	///
35010	"전주시"	///
35011	"전주시 완산구"	///
35012	"전주시 덕진구"	///
35020	"군산시"	///
35030	"익산시"	///
35040	"정읍시"	///
35050	"남원시"	///
35060	"김제시"	///
35310	"완주군"	///
35320	"진안군"	///
35330	"무주군"	///
35340	"장수군"	///
35350	"임실군"	///
35360	"순창군"	///
35370	"고창군"	///
35380	"부안군"	///
36010	"목포시"	///
36020	"여수시"	///
36030	"순천시"	///
36040	"나주시"	///
36060	"광양시"	///
36310	"담양군"	///
36320	"곡성군"	///
36330	"구례군"	///
36350	"고흥군"	///
36360	"보성군"	///
36370	"화순군"	///
36380	"장흥군"	///
36390	"강진군"	///
36400	"해남군"	///
36410	"영암군"	///
36420	"무안군"	///
36430	"함평군"	///
36440	"영광군"	///
36450	"장성군"	///
36460	"완도군"	///
36470	"진도군"	///
36480	"신안군"	///
37010	"포항시"	///
37011	"포항시 남구"	///
37012	"포항시 북구"	///
37020	"경주시"	///
37030	"김천시"	///
37040	"안동시"	///
37050	"구미시"	///
37060	"영주시"	///
37070	"영천시"	///
37080	"상주시"	///
37090	"문경시"	///
37100	"경산시"	///
37310	"군위군"	///
37320	"의성군"	///
37330	"청송군"	///
37340	"영양군"	///
37350	"영덕군"	///
37360	"청도군"	///
37370	"고령군"	///
37380	"성주군"	///
37390	"칠곡군"	///
37400	"예천군"	///
37410	"봉화군"	///
37420	"울진군"	///
37430	"울릉군"	///
38030	"진주시"	///
38050	"통영시"	///
38060	"사천시"	///
38070	"김해시"	///
38080	"밀양시"	///
38090	"거제시"	///
38100	"양산시"	///
38110	"창원시"	///
38111	"창원시 의창구"	///
38112	"창원시 성산구"	///
38113	"창원시 마산합포구"	///
38114	"창원시 마산회원구"	///
38115	"창원시 진해구"	///
38310	"의령군"	///
38320	"함안군"	///
38330	"창녕군"	///
38340	"고성군"	///
38350	"남해군"	///
38360	"하동군"	///
38370	"산청군"	///
38380	"함양군"	///
38390	"거창군"	///
38400	"합천군"	///
39010	"제주시"	///
39020	"서귀포시"	, replace
destring shigungu, replace force
label value shigungu 시군구
numlabel _all, add 
