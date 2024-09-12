
raw_data = readtable('raw_data_eeg.csv');
%우선 raw data 에서 time, VoidOff, Water filtering 해주기
event1 = 'time';
event2 = 'VoidOff';
event3 = 'Water';

%raw_data 의 column 이름 알아내기. SessionStart 가 아닌 Var1, Var2, Var3, Var4 로 됨. 
raw_data.Properties.VariableNames

% string_compare 을 이용하여 각 이벤트에 대해 비교하여 그 이벤트의 row를 제거
rows_to_remove = strcmp(raw_data.Var1, event1) | strcmp(raw_data.Var1, event2) | strcmp(raw_data.Var1, event3);

% 해당 행들을 제거한 새로운 데이터 생성
filtered_eeg = raw_data(~rows_to_remove, :);

% filtered 된 테이블 생성위해 column name define 해주기
columns = {'Lap', 'NavStart', 'Trial', 'Lap_Trial', 'Context_txt', 'Context_Num', 'Direction', 'Location', 'Association', 'Obj_ID', 'ObjOn', 'ChoiceOn','Choice_Num', 'Choice_txt', 'Correct_Num', 'Correct_txt', 'isTimeout', 'RT', 'ObjOff', 'ITIEnd', 'NavEnd'};

% 62개의 empty row를 가진 테이블 생성 & nan value 로 우선 채워주기 -> preallocation to
% reduce runtime!
cleaned_table = array2table(nan(62, length(columns)), 'VariableNames', columns);

%먼저 Lap 부터 채워주기. 얘는 그냥 lap 의 숫자만 넣으면 되니 따로 데이터 가져올 필요 x
%첫 1~15 까지의 row 는 0으로 채워주기 (pre-ocat)
cleaned_table.Lap(1:15) = 0;

%16번째 row 부터는 1부터 8까지 각 4 개씩 채워주기 (main-ocat)
start_row = 16;

for i = 1:8
    cleaned_table.Lap(start_row:start_row + 3) = i;
    start_row = start_row + 4;  
end

%마지막 15개 row 는 9로 (post-ocat)
cleaned_table.Lap(48:62) = 9;

%Trial 차례: 얘는 그냥 하나씩 for loop 통해서 넣어주기 
neg = -1;

for i = 1:15
    cleaned_table.Trial(i) = neg;
    neg = neg - 1;  
end

pos = 1;
for i = 16:47
    cleaned_table.Trial(i) = pos;
    pos = pos + 1;  
end

for i = 48:62
    cleaned_table.Trial(i) = neg;
    neg = neg - 1;  
end

%Lap_Trial 차례: 얘도 16~47 번째 row 만 1,2,3,4 반복순으로 넣어주기

start_row = 16;

for i = 1:8
    cleaned_table.Lap_Trial(start_row:start_row+3) = [1,2,3,4];
    start_row = start_row + 4;  
end

%이제 이 아래론는 raw_data 보고 채워야하는 것들!
%먼저 Nav_Start 와 Obj_On 을 채울거임. (현재는 Nav_Start 이벤트가 없기 때문에 우선은 Obj_On - 4초로
%하기.) 

%preocat 에서는 PreObjOn, ocat 에서는 ObjOn 으로 나타남.

% 모든 row 순서대로 다 보기. 

temp = 1;  % Initialize temp to track rows in cleaned_table
for i = 1:height(filtered_eeg)
    
    % 'PreObjOn'인 경우에는 그대로 넣어주기
    %여기에 한꺼번에 Object id 도 넣어줄거임~ 얘는 'PreObjOn' 일때 Var4에 나오기 때문에:)
    if strcmp(filtered_eeg.Var1{i}, 'PreObjOn')
        cleaned_table.NavStart(temp) = filtered_eeg.Var2(i);
        cleaned_table.ObjOn(temp) = filtered_eeg.Var2(i);
        cleaned_table.Obj_ID(temp) = filtered_eeg.Var4(i);
        temp = temp + 1;
    
    %  'ObjOn'인 경우에는 ObjOn 은 그대로, NavStart 는 -4초 
    elseif strcmp(filtered_eeg.Var1{i}, 'ObjOn')
        cleaned_table.ObjOn(temp) = filtered_eeg.Var2(i);
        cleaned_table.NavStart(temp) = filtered_eeg.Var2(i) - 4;
        temp = temp + 1;
    end
end

%이번에는 slicing 이 필요한 값들 채워주기! (변환 차트 보고 해야하는 문제) 

ocat_start = 16;
for i = 1:height(filtered_eeg)
    %항상 각 trial 시작하면 그 Trial 의 Type 의 값으로 나옴 (Var4)
    if strcmp(filtered_eeg.Var1{i}, 'Trial')
        temp = num2str(filtered_eeg.Var4(i));
        cleaned_table.Context_Num(ocat_start) = str2double(temp(1));
        cleaned_table.Direction(ocat_start) = str2double(temp(2));
        cleaned_table.Location(ocat_start) = str2double(temp(3));
        cleaned_table.Association(ocat_start) = str2double(temp(4));
        cleaned_table.Obj_ID(ocat_start) = str2double(temp(5));
        ocat_start = ocat_start + 1; 
    end
end

%이제 context_num 을 Context_txt 로 변환 시키기~
%찾아보니 NaN 들은 number/double array 로 되기 때문에 얘네를 우선 string array 로 바꿔줘야함.
cleaned_table.Context_txt = strings(height(cleaned_table), 1); 

for i = 1:height(cleaned_table)
    if cleaned_table.Context_Num(i) == 1
        cleaned_table.Context_txt(i) = "F";
    elseif cleaned_table.Context_Num(i) == 2
        cleaned_table.Context_txt(i) = "C";
    end
end



%이제 ChoiceOn 채울거임~
ocat_start = 16; 

for i = 1:height(filtered_eeg)
    if strcmp(filtered_eeg.Var1{i}, 'ChoiceOn')
        cleaned_table.ChoiceOn(ocat_start) = filtered_eeg.Var2(i); 
        ocat_start = ocat_start + 1;
    end
end

%이제 decision 보고 Correct_Num 채우기

ocat_start = 16; 

for i = 1:height(filtered_eeg)
    if strcmp(filtered_eeg.Var1{i}, 'Decision')
        cleaned_table.Correct_Num(ocat_start) = filtered_eeg.Var2(i); 
        ocat_start = ocat_start + 1;
    end
end

%이걸 바탕으로 Correct_txt 채우기~

ocat_start = 16; 
cleaned_table.Correct_txt = strings(height(cleaned_table), 1); 
cleaned_table.Choice_txt = strings(height(cleaned_table), 1); 
for i = 1:height(cleaned_table)
    %얘는 타임 아웃이니까 Choice_txt 까지 missing 으로 채워주기.
    %isTimeout 까지 채워주기 !
    if cleaned_table.Correct_Num(i) == 2
       cleaned_table.Correct_txt(ocat_start) = "TimeOut"; 
       cleaned_table.Choice_txt(ocat_start) = "missing";
       cleaned_table.isTimeout(ocat_start) = 1;
       ocat_start = ocat_start + 1;
    elseif cleaned_table.Correct_Num(i) == 1
        cleaned_table.Correct_txt(ocat_start) = "Correct";
        cleaned_table.isTimeout(ocat_start) = 0;
        ocat_start = ocat_start + 1;
    elseif cleaned_table.Correct_Num(i) == 0
        cleaned_table.Correct_txt(ocat_start) = "Incorrect"; 
        cleaned_table.isTimeout(ocat_start) = 0;
        ocat_start = ocat_start + 1;
    end
end

%이제 Choice_txt랑 Choice_Num 채워넣을거임~
%내가 할 방식은 일단 loop through 하다가 ChoiceOn 이라는 이벤트가 나오면 그 사이에 ChoiceA 나 
%ChoiceB 가 있는지 보고 있다면 각각 입력해주고 없으면 Choice_Num 비워주고 Choice_txt 는 missing 으로~


ocat_start = 16; 

for i = 1:height(filtered_eeg)
    if strcmp(filtered_eeg.Var1{i}, 'ChoiceOn')
        if strcmp(filtered_eeg.Var1{i+2}, 'ChoiceA')
            cleaned_table.Choice_txt(ocat_start) = 'A';
            cleaned_table.Choice_Num(ocat_start) = 1;
            ocat_start = ocat_start + 1;
        elseif strcmp(filtered_eeg.Var1{i+2}, 'ChoiceB')
            cleaned_table.Choice_txt(ocat_start) = 'B';
            cleaned_table.Choice_Num(ocat_start) = 2;
            ocat_start = ocat_start + 1;
        else
            ocat_start = ocat_start + 1;
        end
    end
end


%RT 넣어주기~ 근데 일단 main ocat 먼저 처리 할거임!
ocat_start = 16; 

for i = 1:height(filtered_eeg)
    if strcmp(filtered_eeg.Var3{i}, 'Duration')
        cleaned_table.RT(ocat_start) = filtered_eeg.Var4(i);
        ocat_start= ocat_start+1;
    end
end

%RT 이젠 pre-ocat 이랑 post-ocat 있는 애들 채워주기. target object 나올때만 카운트하면됨~
trial_num = 0;

for i = 1:height(filtered_eeg)
    if strcmp(filtered_eeg.Var1{i}, 'PreObjOn') || strcmp(filtered_eeg.Var1{i}, 'ObjOn')
        trial_num = trial_num + 1;
        if filtered_eeg.Var4(i) == 12
        Runtime = filtered_eeg.Var2(i+1)- filtered_eeg.Var2(i);
        cleaned_table.RT(trial_num) = Runtime;
        end
    end
end

%이제 ITIEnd 채우기..TrialEnd 로 나타나있음..

ocat_start = 16; 

for i = 1:height(filtered_eeg)
    if strcmp(filtered_eeg.Var1{i}, 'TrialEnd')
        cleaned_table.ITIEnd(ocat_start) = filtered_eeg.Var2(i);
        ocat_start= ocat_start+1;
    end
end

%이제.. NavEnd 채우기.. LapEnd로 나타나있음.. 대신 한개의 랩이 끝날때마다만 넣어야함..
%다른점은 첫 시작이 19번째 셀부터..!

ocat_start = 19; 

for i = 1:height(filtered_eeg)
    if strcmp(filtered_eeg.Var1{i}, 'LapEnd')
        cleaned_table.NavEnd(ocat_start) = filtered_eeg.Var2(i);
        ocat_start= ocat_start+4;
    end
end

%1~15, 48:62
%진짜 마지막!! 이제 pre-ocat 이랑 post-ocat context & association 들 채워주기!! 
%Association, Context_Num, Context_txt 채워야함
%주의할 점은 association 이 1 일때만 
object_finder = 16;
for i = 1:15
    if cleaned_table.Obj_ID(object_finder) == cleaned_table.Obj_ID(i)
        cleaned_table.Association(i) = cleaned_table.Association(object_finder);
        cleaned_table.Context_Num(i) = cleaned_table.Context_Num(object_finder);
        cleaned_table.Context_txt(i) = cleaned_table.Context_txt(object_finder);
    elseif cleaned_table.Obj_ID(object_finder+1) == cleaned_table.Obj_ID(i)
        cleaned_table.Association(i) = cleaned_table.Association(object_finder+1);
        cleaned_table.Context_Num(i) = cleaned_table.Context_Num(object_finder+1);
        cleaned_table.Context_txt(i) = cleaned_table.Context_txt(object_finder+1);
    elseif cleaned_table.Obj_ID(object_finder+2) == cleaned_table.Obj_ID(i)
        cleaned_table.Association(i) = cleaned_table.Association(object_finder+2);
        cleaned_table.Context_Num(i) = cleaned_table.Context_Num(object_finder+2);
        cleaned_table.Context_txt(i) = cleaned_table.Context_txt(object_finder+2);
    elseif cleaned_table.Obj_ID(object_finder+3) == cleaned_table.Obj_ID(i)
        cleaned_table.Association(i) = cleaned_table.Association(object_finder+3);
        cleaned_table.Context_Num(i) = cleaned_table.Context_Num(object_finder+3);
        cleaned_table.Context_txt(i) = cleaned_table.Context_txt(object_finder+3);
    end
end

object_finder = 16;
for i = 48:62
    if cleaned_table.Obj_ID(object_finder) == cleaned_table.Obj_ID(i)
        cleaned_table.Association(i) = cleaned_table.Association(object_finder);
        cleaned_table.Context_Num(i) = cleaned_table.Context_Num(object_finder);
        cleaned_table.Context_txt(i) = cleaned_table.Context_txt(object_finder);
    elseif cleaned_table.Obj_ID(object_finder+1) == cleaned_table.Obj_ID(i)
        cleaned_table.Association(i) = cleaned_table.Association(object_finder+1);
        cleaned_table.Context_Num(i) = cleaned_table.Context_Num(object_finder+1);
        cleaned_table.Context_txt(i) = cleaned_table.Context_txt(object_finder+1);
    elseif cleaned_table.Obj_ID(object_finder+2) == cleaned_table.Obj_ID(i)
        cleaned_table.Association(i) = cleaned_table.Association(object_finder+2);
        cleaned_table.Context_Num(i) = cleaned_table.Context_Num(object_finder+2);
        cleaned_table.Context_txt(i) = cleaned_table.Context_txt(object_finder+2);
    elseif cleaned_table.Obj_ID(object_finder+3) == cleaned_table.Obj_ID(i)
        cleaned_table.Association(i) = cleaned_table.Association(object_finder+3);
        cleaned_table.Context_Num(i) = cleaned_table.Context_Num(object_finder+3);
        cleaned_table.Context_txt(i) = cleaned_table.Context_txt(object_finder+3);
    end
end

%여기서 association 0 인 애들은 다시 1 로 바꿔주고 context 뒤집어 주기!!

for i = 1:15
    if cleaned_table.Association(i) == 0
        if cleaned_table.Context_txt(i) == 'F'
            cleaned_table.Context_txt(i) = 'C';
            cleaned_table.Context_Num(i) = 2;
            cleaned_table.Association(i) = 1;
        else
            cleaned_table.Context_txt(i) = 'F';
            cleaned_table.Context_Num(i) = 1;
            cleaned_table.Association(i) = 1;
        end
    end
end

for i = 48:62
    if cleaned_table.Association(i) == 0
        if cleaned_table.Context_txt(i) == 'F'
            cleaned_table.Context_txt(i) = 'C';
            cleaned_table.Context_Num(i) = 2;
            cleaned_table.Association(i) = 1;
        else
            cleaned_table.Context_txt(i) = 'F';
            cleaned_table.Context_Num(i) = 1;
            cleaned_table.Association(i) = 1;
        end
    end
end

writetable(cleaned_table, 'pilot_saeyi.xlsx');