clear
set more off


use "farm2005.dta", replace
forvalues i=6/21{
destring v`i', replace force
}

forvalues i=24/85{
destring v`i', replace force
}

tostring v2, replace
replace v2="0"+v2 if strlen(v2)==2
egen 시군구=concat(v1 v2)
egen 읍면동=concat(v1 v2 v3)

gen auto=v22
bys 시군구: egen AG_N=total(auto>0)
bys 시군구: gen totalfarm_N=_N

bys 읍면동: egen AG_N2=total(auto>0)
bys 읍면동: gen totalfarm_N2=_N

gen AG_IN_TOWN=AG_N/totalfarm_N
gen AG_IN_TOWN2=AG_N2/totalfarm_N2

egen auto_total=total(auto), by(시군구)
egen greenhouse_total=total(v26), by(시군구)
egen auto_total2=total(auto), by(읍면동)
egen greenhouse_total2=total(v26), by(읍면동)

gen ratio=auto_total/greenhouse_total
gen ratio2=auto_total2/greenhouse_total2
replace ratio2=0 if ratio2==.

duplicates drop 읍면동, force

keep 읍면동 AG_IN_TOWN2 ratio2

export excel using 2005.xlsx, firstrow(var)


*시군구 생성
tostring v2, replace
replace v2="0"+v2 if strlen(v2)==2
egen 시군구=concat(v1 v2)
egen 읍면동=concat(v1 v2 v3)

bys 시군구: egen AG_N=total(auto>0)
bys 읍면동: egen AG_N2=total(auto>0)
bys 시군구: gen totalfarm_N=_N
bys 읍면동: gen totalfarm_N2=_N
gen AG_IN_TOWN=AG_N/totalfarm_N
gen AG_IN_TOWN2=AG_N2/totalfarm_N2


egen auto_total=total(auto), by(읍면동)
egen ordinary_total=total(ordinary), by(읍면동)
egen 버섯재배사_total=total(버섯재배사), by(읍면동)
egen glass_total=total(glass), by(읍면동)
egen etchouse_total=total(etc_house), by(읍면동)
export excel using 2015house.xlsx, firstrow(var)

///////////////////////////////////////////////////////////////////////
drop if v3=="**"
gen auto_m=auto*3.306
replace auto_m=1 if auto_m==0
gen lnauto_m=ln(auto_m)
rename v9 exp


*축산 농가 제외
drop if v52==7

*토지가 0인 농가 제외
drop land
gen land=v11+v18
gen land_m=land*3.306
replace land_m=1 if land_m==0
gen lntotal_land=ln(land_m)
drop if land==0

*시설면적이 양수인 농가
keep if v26>0


merge m:1 읍면동 using "읍면동거리2005.dta", gen(_merge2)
drop if _merge2==2
destring 읍면동거리, replace
gen 읍면동거리km=읍면동거리/1000


*가구원
destring _all, replace force
drop if v5==.
rename v8 age
gen owner=(v9==1) 
rename v10 edu
recode v11 (1=3) (2=2) (3=1) , gen(level)
sort v5
bys v5: egen adultnumber=count(age>=19)

*가구원 데이터 머징
merge 1:m v5 using 2005farmhhm.dta, force
keep if _merge==3

*employment(significant하면 변수를 추가하자)
gen emp_=(v9==9)
egen emp=max(emp_), by(v5)


keep if owner==1


*age
gen elder=(age>=65)
gen age_fifties=(age<50)
gen age_sixtyfour=(age>=50 & age<=64)
gen age_oversixtyfour=elder

*edu를 구분해보자(고졸미만/고졸/대졸) (무학/고졸미만/고졸/2년대졸/4년대졸)

*고졸 미만 (초중졸과 고졸 미만의 평균 임금이 소수점 한 자리까지 유사해서 합침)
gen under_high=0
replace under_high=1 if edu<4
replace under_high=1 if edu==4 & level==1

*고졸(2년제 재학과 4년제 재학을 포함)
gen high_grad=0
replace high_grad=1 if edu==4 & level==2
replace high_grad=1 if edu==5 & level==1 
replace high_grad=1 if edu==6 & level==1 

*대졸
gen bachelor=0
replace bachelor=1 if edu==5 & level==2
replace bachelor=1 if edu==6 & level==2

*대졸포함한 고졸이상
gen overhigh=0
replace overhigh=1 if high_grad==1 | bachelor==1

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

*전업 및 겸업
destring v10, replace force
rename v10 farmtype
label define farmtype 1 "farm_only" 2 "more_farm" 3 "more_others"
label value farmtype farmtype
numlabel _all, add 
tab farmtype, gen(farmtypedummy)
gen 농업수입뿐임=farmtypedummy1
gen 농업수입이많음=farmtypedummy2


*Sales channel
gen sales_channel=v51
gen 농협=sales_channel==3
gen 친환경=(v55==5 & sales_channel==11)
gen 가공업체=sales_channel==9
gen 기타대형유통업체=(sales_channel==7 | sales_channel==8) 
gen 도매시장공판장=(sales_channel==1 | sales_channel==2)
gen 직거래=sales_channel==6

/// v38로 표본을 좁혔을 때만 사용가능
label define sales_channel 1 "도매시장" 2 "산지공판장" 3 "농협농업법인" 4 "정부기관공공비축제등" 5 "수집상중간상인밭떼기등" 6 "개인소비자" 7 "대형유통업체" 8 "대량수요처" 9 "농축산물가공업체" 10 "재래시장", replace
label value sales_channel sales_channel
numlabel _all, add

*생산자 조직 참여
*1. 법인만
gen corporation=0
replace corporation=1 if v47==1 | v48==1 

*2. 작목반만 (논벼 작목반, 기타 작목반 제외)
gen cooperative=0
replace cooperative=1 if v42==1 | v43==1 | v44==1 | v45==1 
label variable v42 "과수작목반"
label variable v43 "채소작목반"
label variable v44 "특용작물작목반"
label variable v45 "화훼작목반"


*Land in ownership(시설작물은 자가 확인 불가)
gen own=v12+v19
gen ownland=own/land
gen Own=(ownland==1)

*Size of Greenhouse (판매금액 넣으면 이것 빼야함)
gen house_size=v26

*sales 변형
gen sales=v50
gen Sales=1 if sales<7
replace Sales=0 if sales==1
replace Sales=2 if sales>=7 & sales<10
replace Sales=3 if sales==10 
replace Sales=4 if sales>=11
tab Sales, gen(salesdummy)
label define Sales 0 "판매없음" 1 "천만미만" 2 "천만이상오천미만" 3 "오천이상일억미만" 4 "일억이상"
label value Sales Sales
numlabel _all, add
gen 천만이상오천미만=salesdummy2
gen 오천이상일억미만=salesdummy3
gen 일억이상=salesdummy4

*rural(11-15:읍 31-47:면 51-80:동)
destring v3, replace
gen rural=(v3<50)


*use of IT devices: 컴퓨터밖에 없음. 자동화 목적도 없음.
gen ITgeneral=(v63==1)

*region
gen province =v1
gen region=0
replace region=1 if province==31
replace region=2 if province==32
replace region=3 if province==33 | province==34 | province==25
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
rename v6 cardnumber
rename v7 crop
rename v8 area
rename v9 노지재배시군구작물판매
rename v10 친환경유무
destring cardnumber  crop area 노지재배 친환경유무, replace force

sort v5

merge 1:m v5 using "2005crop.dta", gen(_merge1) force
keep if _merge1==3

tostring cardnumber crop, replace force
gen cropcode=cardnumber+crop

label define cropcode 201 "시설무" ///
202 "시설배추" 203 "시설시금치" 204 "시설상추" 205 "시설토마토" 206 "시설오이" ///
207 "시설딸기" 208 "시설수박" 209 "시설참외" 2010 "시설호박" 2011 "시설고추" ///
2012 "시설대파" 2013 "시설서양채소" 2014 "시설포도" 2015 "시설감귤" 2016 "시설메론" ///
2017 "시설버섯" 2018 "시설감자" 2019 "시설화훼" 2020 "기타시설작물" 2099 "합계", replace
destring cropcode cardnumber crop, replace 
label value cropcode cropcode
numlabel _all, add 

*경지면적
bys v5: egen 재배면적_=total(area) if crop==99 
egen 재배면적=max(재배면적_), by(v5)

*정책작물
bys v5: gen 오이=area if cropcode==206
bys v5: gen 수박=area if cropcode==208
bys v5: gen 토마토=area if cropcode==205
bys v5: gen 딸기=area if cropcode==207
bys v5: gen 참외=area if cropcode==209
bys v5: gen 파프리카포함서양채소=area if cropcode==2013
bys v5: gen 장미국화포함꽃=area if cropcode==2019
bys v5: gen 멜론포함기타시설작물=area if cropcode==2016
bys v5: gen 버섯=area if cropcode==2017

egen 오이_=max(오이), by(v5) 
egen 수박_=max(수박), by(v5) 
egen 토마토_=max(토마토), by(v5) 
egen 딸기_=max(딸기), by(v5) 
egen 참외_=max(참외), by(v5) 
egen 파프리카포함서양채소_=max(파프리카포함서양채소), by(v5) 
egen 장미국화포함꽃_=max(장미국화포함꽃), by(v5) 
egen 멜론포함기타시설작물_=max(멜론포함기타시설작물), by(v5) 
egen 버섯_=max(버섯), by(v5)

replace 오이_=0 if 오이_==.
replace 수박_=0 if 수박_==.
replace 토마토_=0 if 토마토_==.
replace 딸기_=0 if 딸기_==.
replace 참외_=0 if 참외_==.
replace 파프리카포함서양채소_=0 if 파프리카포함서양채소_==.
replace 장미국화포함꽃_=0 if 장미국화포함꽃_==.
replace 멜론포함기타시설작물_=0 if 멜론포함기타시설작물_==.
replace 버섯_=0 if 버섯_==.

gen 정책작물=오이_+수박_+토마토_+딸기_+참외_+파프리카포함서양채소_+장미국화포함꽃_+멜론포함기타시설작물_


bys v5: gen cropnumber=_N
bys v5: gen croporder=_n

gsort v5 -area
order v5 area
drop cardnumber  _merge* 노지재배시군구작물판매 crop 재배면적_ ///
친환경유무 오이 수박 토마토 딸기 참외 파프리카포함서양채소 장미국화포함꽃 멜론포함기타시설작물 버섯

*이유는 모르겠는데 reshape하면 관측치가 1개 사라진다.
reshape wide cropcode area, i(v5) j(croporder)
forvalues i=1/50 {
replace area`i'=0 if area`i'==.
}

gen 오이비율=오이_/재배면적
gen 수박비율=수박_/재배면적
gen 토마토비율=토마토_/재배면적
gen 딸기비율=딸기_/재배면적
gen 참외비율=참외_/재배면적
gen 파프리카포함서양채소비율=파프리카포함서양채소_/재배면적
gen 장미국화포함꽃비율=장미국화포함꽃_/재배면적
gen 멜론포함기타시설작물비율=멜론포함기타시설작물_/재배면적
gen 버섯비율=버섯_/재배면적
gen 정책작물비율=정책작물/재배면적


*dependent variable
gen AG_GREEN=auto/house_size
gen lntotal_land2=lntotal_land^2

rename v52 mainincome
label define mainincome 1 "논벼" 2 "과수" 3 "특용작물" 4 "채소" 5 "화훼" 6 "일반밭작물" 7 "축산" 8 "양잠기타"
label value mainincome mainincome
numlabel _all, add 
gen year2015=0
gen year2010=0

gen 농업뿐or농업수입이많음=(farmtypedummy1==1 | farmtypedummy2==1)
gen exp2=exp^2/100

*자동화 비닐하우스 면적 4분위로 나눔. 1이 최하위 25% 그룹
xtile auto_4=auto if auto>0, nquantiles(4)

churdle linear lnauto age_sixtyfour age_oversixtyfour ///
 exp overhigh  ITgeneral  친환경 ///
 ownland cropnumber corporation ///
 cooperative 농업수입뿐임 농업수입이많음 adultnumber   ///
 lntotal_land lntotal_land2 rural AG_IN_TOWN2  ///
정책작물비율  ///
강원 충청 전라 경상 제주  if v52==4 & v53==2, ///
select(  age_sixtyfour age_oversixtyfour ///
exp overhigh ITgeneral 친환경 ///
 ownland cropnumber corporation ///
 cooperative 농업수입뿐임 농업수입이많음 adultnumber   ///
 lntotal_land lntotal_land2 rural AG_IN_TOWN2  ///
정책작물비율 ///
강원 충청 전라 경상 제주 ) ll(0) vce(robust) 
estimate store msquare
estout msquare, cell( b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
starlevels(* 0.1 ** 0.05 *** 0.01) legend varwidth(25)
*exp의 극점
di -_b[exp]/(2*_b[exp2])
esttab using POLS5.csv

