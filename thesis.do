
clear
cap log close
set more off

cd C:\Users\JJH\Desktop\saesol\farm
log using thesis.smcl, replace

use farm2015.dta


************************************data management***************************************************

*축산 농가 제외
drop if v107==17

*시설 농가만 남겨보기
keep if v107==4 | v107==6 | v107==8 | v107==10 | v107==12 | v107==14 | v107==16

*시설작물 재배 농가만
keep if v38==1

*시설면적 여부 농가
keep if v39==1

*한 가구수가 읍면동에 가구수가 3개 미만인 경우 *처리
* 자동화 비닐하우스 변수 기초 통계량 파악
sum v40 if v40>0
count if v40>0

*결측치 0으로 만들기
recode auto (mis=0)
destring, replace force

*renaming
duplicates drop v4, force
keep v4 if v4 < ./// 안먹히므로 마지막 v4=.은 손으로 지운다.
drop in 1087844

rename v106 sales
gen earning=1
replace earning=2 if sales==6|sales==7|sales==8
replace earning=3 if sales==9
replace earning=4 if sales==10|sales==1|sales==12

*earning을 논밭 면적으로 나눠야 할 텐데, 그러면 자동화의미가 없담;ㄹ 어ㅏㅣㅁ;ㅓㄹㅈ / 우선 단일 작물 재배 농가만 대상으로 하자.
recode v131 (1=1) (2=0), gen(employment)
recode v128 (1=1) (2=0), gen(same)
rename v161 computer
rename v162 smartphone
rename v163 etc
rename v168 manage_com
rename v173 manage_smart
rename v178 manage_etc
rename v40 auto
rename v41 ordinary
gen province = v1
replace province=v129 if v128==2
label define province 11 "Seoul" 21 "Busan" 22 "Daegu" 23 "Incheon" 24 "Gwangju" 25 "Daejeon" 26 "Ulsan" 29 "Saejong" 31 "Gyeonggi" 32 "Gangwon" 33 "Chungbuk" 34 "Chungnam" ///
35 "Jeonbuk" 36 "Jeonnam" 37 "Gyeongbuk" 38 "Gyeongnam" 39 "Jaeju" 
label value province province
numlabel _all, add 
gen auto_dummy=0
replace auto_dummy=1 if auto>0
gen ordinary_dummy=0
replace ordinary_dummy=1 if ordinary>0
ta auto_dummy ordinary_dummy, cell
rename v42 버섯재배사
rename v43 glass
rename v44 etc_house

*논밭 전체 면적
gen land=v17+v23
gen APH_ratio=auto/land
su APH_ratio if auto>0

*지역 더미 잘 만들어졌나 확인
egen location=rowtotal(province1 province2 province3 province4 province5 province6 province7 province8 province9 province10 province11 province12 province13 province14 province15 province16 province17)
ta location

*가구키 중복 obs 제거
///egen id=concat(v1 v2 v3 v4)
///encode id, generate(id2015)

*가구원 dataset 정리
destring, replace force
rename v19 owner
rename v16 level
recode level (1=3) (2=2) (3=1) 
rename v15 edu
rename v7 age
rename v18 exp

*작물 dataset 정리
destring, replace force
label define crop 1010100 "nonrice" 1020100 "batrice" 1020300 "barley" 1020300 "corn" ///
1020400 "bean" 1020500 "red_bean" 1020600 "potato" 1020700 "sweet_potato" 2010800 ///
"etc_foodcrop" 2010100 "cabbage" 2010200 "raddish" 2010300 "pepper" 2010400 "spinach" ///
2010500 "lettuce" 2010600 "pumpkin" 2010700 "cucumber" 2010800 "watermelon" 2010900 ///
"tomato" 2011000 "strawberry" 2011100 "oriental melon" 2011200 "western vegetable" ///
2020100 "flower" 2030200 "ornamental crop" 2040100 "pyogo_topbab" 2040200 "pyogo_wonmok" ///
 2050100 "etc_muchrooms" 2060200 "etc_housecrops" 2070100 "mountain_namul" 2080100 ///
 "medicinal_crops" 3010610 "거봉" 3010602 "마스캇베리에이" 3010603 "새단" 3010604 "수옥" /// 
 3010605 "캠벨얼리" 3010606 "홍이슬" 3010607 "흑구슬" 3010608 "흑보석" 3010609 "포도_기타" ///
 3010801 "감평" 3010802 "궁본조생" 3010803 "궁천조생" 3010804 "남감20호" 3010805 "다원조생" ///
 3010806 "한라봉" 3010807 "상도조생" 3010808 "천혜향" 3010809 "유라조생" 3010810 "일남1호" ///
 3010811 "청견" 3010812 "탐도1호" 3010813 "탐라조생" 3010814 "하례조생" 3010815 "홍진조생" ///
 3010816 "온주밀감류" 3010817 "만감류_등" 
label value crop crop
numlabel _all, add 


*APH_ratio
gen land=v17+v23
gen APH_ratio=auto/land
su APH_ratio if auto>0
gen empty=0
replace empty=1 if v17==0 & v23==0

*시설 비중


*집단 4개로 구분(auto only, auto&ordinary, ordinary only,  the others)
gen category=0
replace category=1 if auto>0 & ordinary==0
replace category=2 if auto>0 & ordinary>0
replace category=3 if auto==0 & ordinary>0

ta category, missing

*집단 3개로 구분(auto, ordinary only, the others)
gen category2=0
replace category2=1 if auto>0 
replace category2=2 if auto==0 & ordinary>0
ta category2, missing

**********************merging with household member dataset************************************

merge 1:m v4 using farm_hhm2015.dta, keep(match)
keep if owner==1


*age statistics
su age if category==1
su age if category==2
su age if category==3
su age 

su age if category2==1, detail
su age if category2==2, detail
su age, detail


gen elder=0
replace elder=1 if age>=65
su elder if category==1
su elder if category==2
su elder if category==3
su elder 

gen elder=0
replace elder=1 if age>=65
su elder if category2==1, detail
su elder if category2==2, detail
su elder , detail


*experience statistics
su exp if category==1
su exp if category==2
su exp if category==3
su exp 

su exp if category2==1, detail
su exp if category2==2, detail
su exp, detail
 

*edu를 구분해보자(고졸미만/고졸/대졸) (무학/고졸미만/고졸/2년대졸/4년대졸)

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

*대졸
gen bachelor=0
replace bachelor=1 if edu==5 & level==3
replace bachelor=1 if edu==6 & level==3

/////////////////////////////////////////////////

*초졸 미만
gen no_school=0
replace no_school=1 if edu==1
replace no_school=1 if edu==2 & level==1
replace no_school=1 if edu==2 & level==2

*초졸
gen ele_grad=0
replace ele_grad=1 if edu==2 & level==3
replace ele_grad=1 if edu==3 & level==1
replace ele_grad=1 if edu==3 & level==2

*중졸
gen mid_grad=0
replace mid_grad=1 if edu==3 & level==1
replace mid_grad=1 if edu==4 & level==1
replace mid_grad=1 if edu==4 & level==2

*2년대졸
gen college=0
replace college=1 if edu==5 & level==3

*4년대졸 
gen university=0
replace university=1 if edu==6 & level==3

*education statistics

su under_high if category==1
su under_high if category==2
su under_high if category==3
su under_high 

su under_high if category2==1, detail
su under_high if category2==2, detail
su under_high, detail 

su high_grad if category==1
su high_grad if category==2
su high_grad if category==3
su high_grad 

su high_grad if category2==1, detail
su high_grad if category2==2, detail
su high_grad, detail 

su bachelor if category==1
su bachelor if category==2
su bachelor if category==3
su bachelor 

su bachelor if category2==1, detail
su bachelor if category2==2, detail
su bachelor, detail

*번외
su no_school if category2==1, detail
su no_school if category2==2, detail
su no_school, detail

su ele_grad if category2==1, detail
su ele_grad if category2==2, detail
su ele_grad, detail

su mid_grad if category2==1, detail
su mid_grad if category2==2, detail
su mid_grad, detail

su college if category2==1, detail
su college if category2==2, detail
su college, detail

su university if category2==1, detail
su university if category2==2, detail
su university, detail


*전업 및 겸업
rename v154 farmtype
label define farmtype 1 "farm_only" 2 "more_farm" 3 "more_others"
label value farmtype farmtype
numlabel _all, add 
tab farmtype, gen(farmdummy)

*전업 및 겸업 statistics
su i.farmtype if category==1
su i.farmtype if category==2
su i.farmtype if category==3
su i.farmtype 

su farmdummy* if category2==1, detail
su farmdummy* if category2==2, detail
su farmdummy*, detail

*판매처 v110
recode v110 (3=1) (6=1) (7=1) (8=1) (1=0) (2=0) (4=0) (5=0) (9=0) (10=0), gen(sales_channel)
su sales_channel if category==1
su sales_channel if category==2
su sales_channel if category==3
su sales_channel 

*법인 v117 v118 v119
gen corporation=0
replace corporation=1 if v117==1 | v118==1 | v119==1
su corporation if category==1
su corporation if category==2
su corporation if category==3
su corporation 

*고용 v131
recode v131 (1=1) (2=0), gen(emp)
su emp if category==1
su emp if category==2
su emp if category==3
su emp 

*Land in ownership v10+v19
gen own=v10+v19
gen land_tenure=own/land
su land_tenure if category==1
su land_tenure if category==2
su land_tenure if category==3
su land_tenure 

*use of electronic devices
gen use_elec=0
replace use_elec=1 if manage_smart==1 | manage_com==1 | manage_etc==1
su use_elec if category==1
su use_elec if category==2
su use_elec if category==3
su use_elec 

*discordance
recode same (1=0) (0=1), gen(discord)
su discord if category==1
su discord if category==2
su discord if category==3
su discord 

*rural
gen rural=0
replace rural=1 if v3<50
su rural if category==1
su rural if category==2
su rural if category==3
su rural 

*시군구에서 차지하는 비중(시군구별 자동화 비닐하우스 농가/전체 시설 농가 수)
*1단계: 시군구별 전체 농가 수 _N을 만든다.
bys v2: gen town_housefarm=_N 
*2단계: 시군구 안에서 category==1인 농가의 총 개수를 센다.
bys v2 : count if category==1
*3단계: 시군구별 auto only 의 숫자 변수를 만든다.
gen APH_N=0
replace APH_N=284 if v2==10
replace APH_N=162 if v2==11
replace APH_N=70 if v2==12
replace APH_N=2 if v2==13
replace APH_N=1 if v2==14
replace APH_N=596 if v2==20
replace APH_N=27 if v2==21
replace APH_N=2 if v2==22
replace APH_N=7 if v2==23
replace APH_N=1882 if v2==30
replace APH_N=435 if v2==40
replace APH_N=51 if v2==41
replace APH_N=16 if v2==42
replace APH_N=59 if v2==43
replace APH_N=38 if v2==44
replace APH_N=348 if v2==50
replace APH_N=1 if v2==51
replace APH_N=0 if v2==52
replace APH_N=4 if v2==53
replace APH_N=587 if v2==60
replace APH_N=411 if v2==70
replace APH_N=505 if v2==80
replace APH_N=31 if v2==90
replace APH_N=2 if v2==91
replace APH_N=7 if v2==92
replace APH_N=50 if v2==100
replace APH_N=118 if v2==101
replace APH_N=35 if v2==103
replace APH_N=20 if v2==104
replace APH_N=12 if v2==110
replace APH_N=128 if v2==111
replace APH_N=0 if v2==112
replace APH_N=20 if v2==113
replace APH_N=8 if v2==114
replace APH_N=2 if v2==115
replace APH_N=92 if v2==120
replace APH_N=50 if v2==130
replace APH_N=16 if v2==140
replace APH_N=13 if v2==150
replace APH_N=1 if v2==160
replace APH_N=5 if v2==170
replace APH_N=15 if v2==180
replace APH_N=0 if v2==190
replace APH_N=145 if v2==191
replace APH_N=7 if v2==192
replace APH_N=3 if v2==193
replace APH_N=76 if v2==200
replace APH_N=56 if v2==210
replace APH_N=89 if v2==220
replace APH_N=44 if v2==230
replace APH_N=66 if v2==240
replace APH_N=44 if v2==250
replace APH_N=54 if v2==260
replace APH_N=30 if v2==270
replace APH_N=47 if v2==280
replace APH_N=842 if v2==310
replace APH_N=409 if v2==320
replace APH_N=875 if v2==330
replace APH_N=269 if v2==340
replace APH_N=520 if v2==350
replace APH_N=520 if v2==360
replace APH_N=678 if v2==370
replace APH_N=541 if v2==380
replace APH_N=241 if v2==390
replace APH_N=166 if v2==400
replace APH_N=95 if v2==410
replace APH_N=35 if v2==420
replace APH_N=25 if v2==430
replace APH_N=33 if v2==440
replace APH_N=68 if v2==450
replace APH_N=11 if v2==460
replace APH_N=2 if v2==470
replace APH_N=0 if v2==480

*3단계: auto 비중 변수를 만든다.
gen APH_proportion=APH_N/town_housefarm
*4단계 : 카테고리별로 SU!
su APH_proportion if category==1
su APH_proportion if category==2
su APH_proportion if category==3
su APH_proportion 

*전체에 대해서




*sales 변형

gen sales1=0
replace sales1=1 if sales==2 | sales==3 | sales==4 | sales==5
gen sales2=0
replace sales2=1 if sales==6 | sales==7 | sales==8 
gen sales3=0
replace sales3=1 if sales==9
gen sales4=0
replace sales4=1 if sales==10 | sales==11 | sales==12

*sales statistics
drop if sales==1

su sales1 if category==1
su sales2 if category==1
su sales3 if category==1
su sales4 if category==1

su sales1 if category==2
su sales2 if category==2
su sales3 if category==2
su sales4 if category==2

su sales1 if category==3
su sales2 if category==3
su sales3 if category==3
su sales4 if category==3

su sales1 sales2 sales3 sales4




*region statistics
ta province if auto>0, missing sort
ta province if auto>0 & ordinary==0, missing sort
ta province if ordinary>0, missing sort
ta province if ordinary>0 & auto==0, missing sort
ta province, missing sort

*************************merging with crop dataset************************************

merge 1:m v4 using farm_crop2015.dta, keep(match) gen(_merge2)
bys v4: gen croporder=_n
count if croporder>10
drop area2 주요과수ranking cardnumber
reshape wide crop area, i(v4) j(croporder)

*작물 재배 개수
*1단계: 집단 내 관찰값 만들기
bys v4: gen cropnumber=_N
*2단계: 관찰값에서 중복 제거하기
duplicates drop v4, force
*카테고리별 평균 구하기
su cropnumber if category==1
su cropnumber if category==2
su cropnumber if category==3
su cropnumber

*시군구 작물(시군구 작물을 기르는 농가는 1, 아니면 0)
*1단계 : 시군구작물 재배 농가(card==24)만 남기다.
keep if card==24
*2단계: 항목부호(crop)에서 노지(401*)시설노지(403*)조경수,과수(404*)인 obs은 지운다.
drop if crop<4020100 
drop if crop>4024500
bys v4: gen town_specific_cropnumber=_N
duplicates drop v4, force
*3단계: 카테고리별로 수를 센다!
count if category==1
count if category==2
count if category==3

*card==24이면 1을 주는 변수를 만든다-> 같은 가구 id 내에서 가장 큰 값으로 replace한다 -> reshape한다.
merge 1:m v4 using farm_crop2015.dta, keep(match) gen(_merge2)
bys v4: gen croporder=_n
count if croporder>10
drop area2 주요과수ranking cardnumber
reshape wide crop area, i(v4) j(croporder)

*작물별 구분태그 만들기
gen classification=0
replace classification=1 if 2010500<crop<2011200
replace classification=2 if crop==2010100 | crop==2010400 | crop==2010500
replace classification=3 if crop==2010200
replace classification=4 if crop==2010300
replace classification=5 if crop==2011200
replace classification=6 if crop==2020100 | crop==2030200
replace classification=7 if crop==2040100 | crop==2040200 | crop==2050100
replace classification=8 if crop==2060200
replace classification=9 if crop==2070100 | crop==2080100

*작물 별 비중
label define classification 1 "fruit" 2 "leafy" 3 "root" 4 "pepper" 5 "western" 6 "ornamental" 7 "mushroom" 8 "etc" 9 "wild_medicinal"
label value classification classification 
numlabel _all, add 
ta classification, missing

*9가지 더미 만들기
gen fruit=0
replace fruit=1 if class==1
gen leafy=0
replace leafy=1 if class==2
gen root=0
replace root=1 if class==3
gen pepper=0
replace pepper=1 if class==4
gen western=0
replace western=1 if class==5
gen orna=0
replace orna=1 if class==6
gen mush=0
replace mush=1 if class==7
gen et=0
replace et=1 if class==8
gen wild_medi=0
replace wild_medi=1 if class==9

su fruit if category==1
su fruit if category==2
su fruit if category==3
su fruit 

su leafy if category==1
su leafy if category==2
su leafy if category==3


ta classification if category==1
ta classification if category==2
ta classification if category==3
ta classification 

*지역 변수
gen gg=0
replace gg=1 if v1==11 | v1==23 | v1==31
gen gs=0
replace gs=1 if v1==21 |v1==22 |v1==26 |v1==37|v1==38
gen jr=0
replace jr=1 if v1==24 | v1==35 | v1==36
gen cc=0
replace cc=1 if v1==25 | v1==29 | v1==33 | v1==34
gen gw=0
replace gw=1 if v1==32
gen jj=0
replace jj=1 if v1==39

su gg gs jr cc gw jj if category==1
su gg gs jr cc gw jj if category==2
su gg gs jr cc gw jj if category==3
su gg gs jr cc gw jj 




*crop statistics
ta crop if card==20 & auto>0, sort 
ta crop if card==20 & auto>0 & ordinary==0, sort
ta crop if card==20 & ordinary>0, sort
ta crop if card==20 & ordinary>0 & auto==0, sort
ta crop if card==20, sort

*각 시설별 면적의 합
egen sum_버섯재배사=total(버섯재배사)
egen sum_auto=total(auto)
egen sum_ordinary=total(ordinary)
egen sum_glass=total(glass)
egen sum_etc=total(etc_house)
rename v45 sum_all

*확인용
egen total=rowtotal(sum_버섯재배사 sum_auto sum_ordinary sum_glass sum_etc)
egen sum_N=total(sum_all)

*v39==1인 집단에서 각 시설별 면적 비중
gen auto_ratio=sum_auto/sum_N
gen ordinary_ratio=sum_ordinary/sum_N
gen glass_ratio=sum_glass/sum_N
gen etc_ratio=sum_etc/sum_N
gen 버섯재배사_ratio=sum_버섯재배사/sum_N
su auto_ratio ordinary_ratio glass_ratio etc_ratio 버섯재배사_ratio
egen ratio_total=rowtotal(auto_ratio ordinary_ratio glass_ratio etc_ratio 버섯재배사_ratio)
su ratio_total

*1.dataset을 시설작물을 수확한 집단으로 제한 -> 쓰면 안됨. 작물까지 머징한 상태에서 가구 아이디가 중복이기 때문.
keep if card==20
///141,474

*서울을 base로 한다(차지하는 비중이 가장 적어서)
drop province1

*regression
logit auto_dummy province* under_high high_grad1 bachelor age exp male i.earning crop
tobit auto province* under_high high_grad1 bachelor age exp male i.earning crop
npregress kernel auto_dummy province* under_high high_grad1 bachelor age exp male i.earning crop
cmp setup

*2.dataset을 지난 1년 간 시설 작물을 재배한 집단으로 제한
keep if v39==1
///103,617 124,989

*3.dataset을 지난 1년 간 판매를 목적으로 시설 작물을 수확한 집단으로 제한
keep if v38==1 
///490,007 103,618

*4.dataset을 시설 면적의 합계가 0 초과인 집단으로 제한(2와 같음)
keep if sum_all>0
///577,889 124,989

xi: logit auto_dummy i.province* i.under_high i.high_grad1 i.bachelor age exp i.female i.sales

tobit auto i.province* i.under_high i.high_grad i.bachelor age exp i.female i.sales

*data slide stat(모집단은 시설면적 여부에서 예라고 대답한 농가) 다음부터는 egen rowmean써
keep if v39==1

*자동화 비닐하우스/비닐하우스 only 가구 비중
count if auto>0
count if category==3

*APH 가 전체 시설 면적에서 차지하는 비중
egen total_greenhouse=total(v45)
egen total_APH=total(auto)
gen total_APH_size_rate=total_APH/total_greenhouse

*비닐하우스가 전체 시설 면적에서 차지하는 비중
egen total_PH=total(ordinary)
gen total_PH_size_rate=total_PH/total_greenhouse

*버섯재배사가 전체 시설 면적에서 차지하는 비중
egen total_버섯재배사=total(v42)
gen total_버섯재배사_rate=total_버섯재배사/total_greenhouse

*유리 온실이 전체 시설 면적에서 차지하는 비중
egen total_glass=total(v43)
gen total_glass_rate=total_glass/total_greenhouse

*기타 시설이 전체 시설 면적에서 차지하는 비중
egen total_otherhouse=total(v44)
gen total_otherhouse_rate=total_otherhouse/total_greenhouse

*2010년 버젼
gen category=0
replace category=1 if auto>0 & ordinary==0
replace category=2 if auto>0 & ordinary>0
replace category=3 if auto==0 & ordinary>0
replace category=4 if auto==0 & ordinary==0
ta category, missing

keep if v49==1
*자동화 비닐하우스/비닐하우스 only 가구 비중
count if auto>0
count if category==3

*APH 가 전체 시설 면적에서 차지하는 비중
egen total_greenhouse=total(v48)
egen total_APH=total(auto)
gen total_APH_size_rate=total_APH/total_greenhouse

*비닐하우스가 전체 시설 면적에서 차지하는 비중
egen total_PH=total(ordinary)
gen total_PH_size_rate=total_PH/total_greenhouse

*2005년 버젼
gen category=0
replace category=1 if auto>0 & ordinary==0
replace category=2 if auto>0 & ordinary>0
replace category=3 if auto==0 & ordinary>0
replace category=4 if auto==0 & ordinary==0
ta category, missing

keep if v26>0

*자동화 비닐하우스/비닐하우스 only 가구 비중
count if auto>0
count if category==3

*APH 가 전체 시설 면적에서 차지하는 비중
egen total_greenhouse=total(v26)
egen total_APH=total(auto)
gen total_APH_size_rate=total_APH/total_greenhouse

*비닐하우스가 전체 시설 면적에서 차지하는 비중
egen total_PH=total(ordinary)
gen total_PH_size_rate=total_PH/total_greenhouse

*total greenhouse
su v45 if category==1
su v45 if category==2
su v45 if category==3
su v45 
