%  eegmarkertime 이라는 테이블은 상언 박사님이 주신 matrices 들을 합친 테이블임!
% 'event_name' and 'event_time' 이라는 새로운 column 만들기
eegmarkertime.event_name = strings(height(eegmarkertime), 1);  
eegmarkertime.event_time = zeros(height(eegmarkertime), 1);   


columnNames = rawdataeeg.Properties.VariableNames;

disp(columnNames);

rawdataeeg.SessionStart = string(rawdataeeg.SessionStart);

%엑셀에서 했던 것 처럼 raw_data 에서 time, voidoff, water 지워주기
rowsToRemove = contains(rawdataeeg.SessionStart, {'time', 'VoidOff', 'Water'}, 'IgnoreCase', true);

rawdataeeg = rawdataeeg(~rowsToRemove, :);

temp = 1; 

for i = 1:height(eegmarkertime)
    if eegmarkertime.markerlist(i) == 102
        eegmarkertime.event_name(i) = "ODT_Start";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'OCP_on')  
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j);  
                temp = j + 1;  
                break; 
            end
        end
        
    elseif eegmarkertime.markerlist(i) == 103
        eegmarkertime.event_name(i) = "ODT_End";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'OCP_off')  
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j);  
                temp = j + 1;  
                break; 
            end
        end

    elseif eegmarkertime.markerlist(i) == 104
        eegmarkertime.event_name(i) = "Main_OCAT_Start"; 
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'LapStart')  
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j);  
                temp = j + 1;  
                break;  
            end
        end

    elseif eegmarkertime.markerlist(i) == 105
        eegmarkertime.event_name(i) = "Main_OCAT_End";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'LapEnd')  
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

    elseif eegmarkertime.markerlist(i) == 107
        eegmarkertime.event_name(i) = "Lap_End";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'LapEnd')  
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                %temp = j + 1; 
                break; 
            end
        end

    elseif eegmarkertime.markerlist(i) == 108
        eegmarkertime.event_name(i) = "Nav_Start";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'TrialStart') && strcmpi(rawdataeeg.SessionStart(j+2), 'ObjOn')  
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j+2) - 4; 
                %temp = j + 1; 
                break;
                %얘는 turn 이 있을 경우에!
            elseif  strcmpi(rawdataeeg.SessionStart(j), 'TrialEnd') && strcmpi(rawdataeeg.SessionStart(j+5), 'ObjOn')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j+5) - 4; 
                %temp = j + 1; 
                break;
            end
        end

     elseif eegmarkertime.markerlist(i) == 109
        eegmarkertime.event_name(i) = "Choice_On";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ChoiceOn')  
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

     elseif eegmarkertime.markerlist(i) == 110
        eegmarkertime.event_name(i) = "Decision";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'Decision')
                %decision 은 button 누른 뒤 duration 값을 더함. 
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j-1) +rawdataeeg.VarName4(j) ; 
                temp = j + 1; 
                break; 
            end
        end

     elseif eegmarkertime.markerlist(i) == 111
        eegmarkertime.event_name(i) = "Turn_Start";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'TurnStart') 
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

     elseif eegmarkertime.markerlist(i) == 112
        eegmarkertime.event_name(i) = "Turn_End";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'TurnEnd')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

     elseif eegmarkertime.markerlist(i) == 113
        eegmarkertime.event_name(i) = "Button_A";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ButtonA')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

     elseif eegmarkertime.markerlist(i) == 114
        eegmarkertime.event_name(i) = "Object_4_On";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ObjOn') || strcmpi(rawdataeeg.SessionStart(j), 'PreObjOn')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

      elseif eegmarkertime.markerlist(i) == 115
        eegmarkertime.event_name(i) = "Object_5_On";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ObjOn') || strcmpi(rawdataeeg.SessionStart(j), 'PreObjOn')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

     elseif eegmarkertime.markerlist(i) == 116
        eegmarkertime.event_name(i) = "Object_6_On";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ObjOn') || strcmpi(rawdataeeg.SessionStart(j), 'PreObjOn')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

     elseif eegmarkertime.markerlist(i) == 117
        eegmarkertime.event_name(i) = "Object_7_On";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ObjOn') || strcmpi(rawdataeeg.SessionStart(j), 'PreObjOn')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

      elseif eegmarkertime.markerlist(i) == 118
        eegmarkertime.event_name(i) = "Object_12_On";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'PreObjOn')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

      elseif eegmarkertime.markerlist(i) == 123
        eegmarkertime.event_name(i) = "Button_B";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ButtonB')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

      elseif eegmarkertime.markerlist(i) == 124
        eegmarkertime.event_name(i) = "Object_4_Off";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ObjOff') || strcmpi(rawdataeeg.SessionStart(j), 'PreObjOff')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

      elseif eegmarkertime.markerlist(i) == 125
        eegmarkertime.event_name(i) = "Object_5_Off";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ObjOff') || strcmpi(rawdataeeg.SessionStart(j), 'PreObjOff')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

      elseif eegmarkertime.markerlist(i) == 126
        eegmarkertime.event_name(i) = "Object_6_Off";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ObjOff') || strcmpi(rawdataeeg.SessionStart(j), 'PreObjOff')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

      elseif eegmarkertime.markerlist(i) == 127
        eegmarkertime.event_name(i) = "Object_7_Off";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'ObjOff') || strcmpi(rawdataeeg.SessionStart(j), 'PreObjOff')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

      elseif eegmarkertime.markerlist(i) == 160
        eegmarkertime.event_name(i) = "Object_12_Off";
        
        for j = temp:height(rawdataeeg)
            if strcmpi(rawdataeeg.SessionStart(j), 'PreObjOff')
                eegmarkertime.event_time(i) = rawdataeeg.VarName2(j); 
                temp = j + 1; 
                break; 
            end
        end

    end
end

writetable(eegmarkertime, 'eegmarkertime.xlsx');