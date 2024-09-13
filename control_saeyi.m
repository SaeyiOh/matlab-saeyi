% event_table_MR 엑셀 파일 불러오기!
filename = 'event_table_MR.xlsx';

% sheet 이름 가져오기
sheets = sheetnames(filename);

% 모든 데이터 다 담아줄 빈 테이블 생성
combined_data = table();

% for loop 을 통해 모든 sheet 하나하나 봐주기
for i = 1:numel(sheets)
    sheet_data = readtable(filename, 'Sheet', sheets{i});
    
    % ParticipantID 라는 새로운 variable / column 형성하기
    sheet_data.ParticipantID =repmat(sheets{i}, height(sheet_data), 1);
    
    % 데이터를 combined_data 라는 전체 데이터에 합쳐주기
    combined_data = [combined_data;sheet_data];
end

if ~isstring(combined_data.ParticipantID)
    combined_data.ParticipantID = string(combined_data.ParticipantID);
end

if ~isstring(info_data.ParticipantID)
    combined_data.ParticipantID = string(combined_data.ParticipantID);
end


%https://kr.mathworks.com/matlabcentral/answers/82362-deleting-part-of-a-string
%sub-__ 의 형태보다는 그냥 숫자로만 나타내기 위해서 sub- 지워주기

combined_data.ParticipantID = regexprep(combined_data.ParticipantID, 'sub-', '');
info_data.ParticipantID = regexprep(info_data.ParticipantID, 'sub-', '');

% info_data 에서 가져올 column 들만 filter 하기
info_data = info_data(:, {'ParticipantID', 'Age', 'Sex'});

% 그리고 우선 숫자에서 string 으로 바꿔주기!
info_data.ParticipantID = string(info_data.ParticipantID);

% outer join 을 통해 merge 진행
merged_data = outerjoin(combined_data, info_data, 'LeftKeys', 'ParticipantID', 'RightKeys', 'ParticipantID', 'MergeKeys', true);

%gender 과 RT 보는거~
%우선 participant id 로 grouping 을 진행한다음에 사람별 average RT 계산해서 넣어주기
%그런 다음 F/M 으로 나누어서 scatterplot / 제작

% rt 가 비어있거나 0 보다 작은 경우를 없애주기!!
valid_data = merged_data(~isnan(merged_data.RT) & merged_data.RT > 0, :);

% ParticipantID 로 그룹핑 해준다음에 각 RT 를 평균내서 넣기.
participant_stats = grpstats(valid_data, 'ParticipantID', {'mean'}, 'DataVars', 'RT');

% 다시 gender 이랑 merging 해주기!
[~, idx] = ismember(participant_stats.ParticipantID, merged_data.ParticipantID);
participant_stats.Sex = merged_data.Sex(idx);

% scatterplot 을 위해서 categorical 로 만들어 주기. 
participant_stats.ParticipantID = categorical(participant_stats.ParticipantID);  

% ParticipantID가 string 이도록 세팅 (number 이니까 숫자로 되어있을 수 있음.)
merged_data.ParticipantID = string(merged_data.ParticipantID);

% format 맞춰주기위해서 0으로 채워넣기!!
merged_data.ParticipantID = pad(merged_data.ParticipantID, 2, 'left', '0');

% 다시 mergeing !!
[~, idx] = ismember(participant_stats.ParticipantID, merged_data.ParticipantID);

% valid 한 index 만 찾아서 넣기.
valid_idx = idx > 0; 
participant_stats = participant_stats(valid_idx, :);
idx = idx(valid_idx); 

% Sex 가 지금 categorical 이어서 오류가 났음 --> String 으로 변환
if iscategorical(merged_data.Sex)
    merged_data.Sex = string(merged_data.Sex);
end

% gender value 넣어주기~
participant_stats.Sex = merged_data.Sex(idx);

% 이제 t-test 해보기!!!between male and female reaction times
male_RT = participant_stats.mean_RT(strcmp(participant_stats.Sex, 'M'));
female_RT = participant_stats.mean_RT(strcmp(participant_stats.Sex, 'F'));

% 충분한 데이터가 있을시에만 테스트 진행하도록!! 
if length(male_RT) > 1 && length(female_RT) > 1
    [~, p_value, ci, stats] = ttest2(male_RT, female_RT);
    
    % 프린드해주기~ 결과를 직접 보기 위해
    fprintf('p-value from t-test: %.4f\n', p_value);
    disp('Confidence Interval:');
    disp(ci);
    disp('Test Statistics:');
    disp(stats);
else
    disp('데이터 충분하지 않음. 다시!!!');
end

% gender로 일단 데이터 나누기!!
male_RT = participant_stats.mean_RT(strcmp(participant_stats.Sex, 'M'));
female_RT = participant_stats.mean_RT(strcmp(participant_stats.Sex, 'F'));

% female & male 의 평균 RT 값..
mean_RT_male = mean(male_RT);
mean_RT_female = mean(female_RT);

% 일단 t-test between gender (근데 각각!) and RT 해주기!
% 에러가 많이 났어서 꼭 else 케이스 써줌~
if length(male_RT) > 1 && length(female_RT) > 1
    [~, p_value, ci, stats] = ttest2(male_RT, female_RT);
    
    fprintf('p-value from t-test: %.4f\n', p_value);
    disp('Confidence Interval:');
    disp(ci);
    disp('Test Statistics:');
    disp(stats);
else
    disp('에러! 다시 코드 고치기');
end

% RT 만 보여주는거 ~
fprintf('Mean Reaction Time for Males: %.4f\n', mean_RT_male);
fprintf('Mean Reaction Time for Females: %.4f\n', mean_RT_female);

% https://kr.mathworks.com/matlabcentral/answers/626198-how-to-calculate-the-pearson-correlation-coefficient-between-the-bits-of-a-20-bit-hash-value
% pearson correlation coefficient 계산하는거~
r_male = corrcoef((1:length(male_RT))', male_RT); 
r_female = corrcoef((1:length(female_RT))', female_RT);

r_value_male = r_male(1,2);
r_value_female = r_female(1,2);

fprintf('Correlation coefficient (r) for males: %.4f\n', r_value_male);
fprintf('Correlation coefficient (r) for females: %.4f\n', r_value_female);

% 박스플랏으로 전체적인 데이터 보기~
figure;
boxplot(participant_stats.mean_RT, participant_stats.Sex);
title('Boxplot of Reaction Time by Gender');
ylabel('Average Reaction Time (seconds)');
xlabel('Gender');

%age 랑 reaction time 보는거!!

% 위에랑 같지만 이제 age 를 추가해주기~
[~, idx] = ismember(participant_stats.ParticipantID, merged_data.ParticipantID);
participant_stats.Age = merged_data.Age(idx);

% RT 랑 age 를 scatterplot 에 visualize!
figure;
scatter(participant_stats.Age, participant_stats.mean_RT, 'filled');
xlabel('Age');
ylabel('Average Reaction Time (seconds)');
title('Scatter Plot of Reaction Time by Age');

% linear model 피팅해주고
mdl_age = fitlm(participant_stats.Age, participant_stats.mean_RT);
disp(mdl_age);

% scatterplot 에 regression line 추가해주기. 
hold on;
plot(mdl_age);
hold off;

%마지막.. objectID 가 5일때 각 context 에 따른 RT

%일단 빈 테이블 생성
result_table = table();

% ParticipantIDs 별로 해줘야하니 unique 한 value 뽑아주기
unique_participants = unique(merged_data.ParticipantID);

% 각 피험자별로
for i = 1:numel(unique_participants)
    participant_id = unique_participants{i};
    
    participant_data = merged_data(strcmp(merged_data.ParticipantID, participant_id), :);
    
    % main OCAT 테스크에서만 direction 에 value 가 있으니까 이거 체크해줘서 
    %없음 삭제해주기.
    if iscell(participant_data.Direction)
        valid_rows = ~cellfun(@isempty, participant_data.Direction);
    else
        valid_rows = ~isnan(participant_data.Direction) & participant_data.Direction ~= 0;
    end
    
    % 위에 valid_rows 로 데이터 필터 해주기!!
    main_ocat_data = participant_data(valid_rows, :);
    
    % OBJ_5 에만 관심이 있으니까 얘만 빼주고
    obj_5_data = main_ocat_data(main_ocat_data.Obj_ID == 5, :);
   
    
    % Obj_ID == 5 인것만 보기
    for j = 1:height(obj_5_data)
        % context 랑 association 봐주기
        context_txt = obj_5_data.Context_txt{j};
        association = obj_5_data.Association(j);
        
        % 만약 association 이 0 이면 context 반대로 바꿔주기!!!
        if association == 0
            if strcmp(context_txt, 'F')
                 % F 에서 C 로~
                context_txt = 'C';
            elseif strcmp(context_txt, 'C')
                 % C 에서 F 로~
                context_txt = 'F';
            end
        end
        
        % RT 가져오기.
        rt_value = obj_5_data.RT(j);
        
        % result_table 에 가져오기.
        new_row = {participant_id, context_txt, rt_value};
        result_table = [result_table; new_row]; 
    end
end

% column name 다시 동일하게 변경해주기~
result_table.Properties.VariableNames = {'ParticipantID', 'Context', 'RT'};

%--

% C 랑 F 구분해주기~ 
forest_data = result_table(strcmp(result_table.Context, 'F'), :);
city_data = result_table(strcmp(result_table.Context, 'C'), :);

% 각각의 RT 구하기!!
mean_rt_forest = mean(forest_data.RT);
mean_rt_city = mean(city_data.RT);

fprintf('Mean Reaction Time for Forest (F): %.4f seconds\n', mean_rt_forest);
fprintf('Mean Reaction Time for City (C): %.4f seconds\n', mean_rt_city);

% RT  Forest/ City 
[~, p_value, ci, stats] = ttest2(forest_data.RT, city_data.RT);


fprintf('p-value from t-test: %.4f\n', p_value);
disp('Confidence Interval:');
disp(ci);
disp('Test Statistics:');
disp(stats);

% mean 과 stdev 계산하기 한꺼번에!!
group_stats = grpstats(result_table, 'Context', {'mean', 'std'}, 'DataVars', 'RT');

% 에러바 있는 bar graph!!
figure;
bar(categorical(group_stats.Context), group_stats.mean_RT);
hold on;
errorbar(categorical(group_stats.Context), group_stats.mean_RT, group_stats.std_RT, '.');
hold off;
xlabel('Context (F = Forest, C = City)');
ylabel('Mean Reaction Time (seconds)');
title('Mean Reaction Time by Context with Error Bars');
