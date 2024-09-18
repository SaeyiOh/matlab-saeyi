%우선 mergeddata 와 동일하게 Participant ID 형태 동일하게!
sbjperform.ParticipantID = regexprep(sbjperform.ParticipantID, 'sub-', '');

% Main-OCAT RT 를 위해 1~32 까지의 트라이얼들만 걸러주기
filtered_data = mergeddata(mergeddata.Trial >= 1 & mergeddata.Trial <= 32, :);

% 각 피험자별 main task RT 계산
average_RT_per_participant = varfun(@mean, filtered_data, 'InputVariables', 'RT', 'GroupingVariables', 'ParticipantID');

% merging! 근데 ODT_RT 만 합쳐주기
combined_table = outerjoin(average_RT_per_participant, sbjperform(:, {'ParticipantID', 'ODT_RT'}),'Keys', 'ParticipantID', 'MergeKeys', true, 'Type', 'full');

% column 이름 다시~
combined_table.Properties.VariableNames{'mean_RT'} = 'Main_OCAT_RT';

% nan 이었던 row 없애주기
cleaned_data = combined_table(~isnan(combined_table.Main_OCAT_RT) & ~isnan(combined_table.ODT_RT), :);

% pearson correlation coefficient 계산!
[r, p_value] = corr(cleaned_data.Main_OCAT_RT, cleaned_data.ODT_RT);

%결과 표시~
fprintf('Pearson Correlation Coefficient: %.4f\n', r);
fprintf('p-value: %.4f\n', p);

% scatterplot 그려주기
figure;
scatter(cleaned_data.Main_OCAT_RT, cleaned_data.ODT_RT, 'filled');
hold on;

% regression line polyfit 으로 그려주기
coefficients = polyfit(cleaned_data.Main_OCAT_RT, cleaned_data.ODT_RT, 1); % Linear fit
y_fit = polyval(coefficients, cleaned_data.Main_OCAT_RT);
plot(cleaned_data.Main_OCAT_RT, y_fit, '-r', 'LineWidth', 2);
text(min(cleaned_data.Main_OCAT_RT), max(cleaned_data.ODT_RT), ['r = ' num2str(r)], 'FontSize', 12);

% 이름 세팅~
xlabel('Main OCAT RT');
ylabel('ODT RT');
title('Correlation between Main OCAT RT and ODT RT');
grid on;
hold off;

