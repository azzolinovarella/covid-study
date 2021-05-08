classdef CovidVisualizationApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        CovidVisualizationAppUIFigure  matlab.ui.Figure
        UIAxes                         matlab.ui.control.UIAxes
        CountryListBoxLabel            matlab.ui.control.Label
        CountryListBox                 matlab.ui.control.ListBox
        StateListBoxLabel              matlab.ui.control.Label
        StateListBox                   matlab.ui.control.ListBox
        MovingAverageSpinnerLabel      matlab.ui.control.Label
        MovingAverageSpinner           matlab.ui.control.Spinner
        OptionsSwitchLabel             matlab.ui.control.Label
        OptionsSwitch                  matlab.ui.control.Switch
        PlotKnobLabel                  matlab.ui.control.Label
        PlotKnob                       matlab.ui.control.DiscreteKnob
        UpdateDatabaseButton           matlab.ui.control.Button
        UpdateLabel                    matlab.ui.control.Label
    end

    
    properties (Access = private)
        Cases  % Database with all the new cases
        Deaths  % Database with all the new deaths
        Dates  % Cell of dates 
        CountriesAndStates % Cell of countries and States        
        PlaceCases  % Cases of the selected place
        PlaceDeaths  % Deaths of the selected place
    end
    
    methods (Access = private)
        
        function plotData(app)
            % Getting usefull information
            country = app.CountryListBox.Value;
            state = app.StateListBox.Value;
            opt = app.OptionsSwitch.Value;
            knopf = app.PlotKnob.Value;            
            num_date = datenum(app.Dates);
            avg = app.MovingAverageSpinner.Value;
            
            % Retrieving the data
            da_cases = app.PlaceCases;
            da_deaths = app.PlaceDeaths;               
            
            % Reseting the graph
            cla(app.UIAxes, 'reset')
            
            % Editting the y and x labels 
            grid(app.UIAxes, 'on')
            xlim(app.UIAxes, [num_date(1) num_date(end)])
            datetick(app.UIAxes, 'x', 'dd/mm/yy', 'keepticks', 'keeplimits')
                                    
            if knopf == "Both"                   
                
                % Changing the title        
                if opt == "Culmulative" 
                    full_title = sprintf('All cases and deaths of COVID-19 for %s (considering %s region and %i-day mean)', country, state, avg);
                else  % i.e., opt == "Daily"
                    full_title = sprintf('New cases and deaths of COVID-19 for %s (considering %s region and %i-day mean)', country, state, avg);
                end
               
                title(app.UIAxes, full_title) 
                
                % Editing the Y axis and ploting the data
                yyaxis(app.UIAxes, 'left')
                ylabel(app.UIAxes, 'New cases')
                ylim(app.UIAxes, [0, max(cell2mat(da_cases))])
                yticks(app.UIAxes, linspace(min(cell2mat(da_cases)), max(cell2mat(da_cases)), 10))
                ytickformat(app.UIAxes, '%d')
                app.UIAxes.YAxis(1).Exponent = 0;
                bar(app.UIAxes, datenum(app.Dates), cell2mat(da_cases), 'b')
                
                yyaxis(app.UIAxes, 'right')
                ylabel(app.UIAxes, 'New deaths')
                ylim(app.UIAxes, [0, max(cell2mat(da_deaths))])
                ytickformat(app.UIAxes, '%d')
                app.UIAxes.YAxis(2).Exponent = 0;
                plot(app.UIAxes, datenum(app.Dates), cell2mat(da_deaths), 'r')                                                                      
               
                return
                
            elseif knopf == "Cases"
                
                % Changing the title        
                if opt == "Culmulative" 
                    full_title = sprintf('All cases of COVID-19 for %s (considering %s region and %i-day mean)', country, state, avg);
                else  % i.e., opt == "Daily"
                    full_title = sprintf('New cases of COVID-19 for %s (considering %s region and %i-day mean)', country, state, avg);
                end
                
                title(app.UIAxes, full_title)
                
                % Editing the left Y axis ploting only the New Cases data
                ylabel(app.UIAxes, 'New cases')
                ylim(app.UIAxes, [0, max(cell2mat(da_cases))])
                yticks(app.UIAxes, linspace(min(cell2mat(da_cases)), max(cell2mat(da_cases)), 10))
                ytickformat(app.UIAxes, '%d')
                app.UIAxes.YAxis.Exponent = 0;
                bar(app.UIAxes, datenum(app.Dates), cell2mat(da_cases), 'b')
                
                return
                
            else  % i.e. knopf == "Deaths"
                   
                % Changing the title        
                if opt == "Culmulative"
                    full_title = sprintf('All deaths of COVID-19 for %s (considering %s region and %i-day mean)', country, state, avg);
                else  % i.e., opt == "Daily"
                    full_title = sprintf('New deaths of COVID-19 for %s (considering %s region and %i-day mean)', country, state, avg);
                end
                
                title(app.UIAxes, full_title)
                
                % Editing the rigth Y axis and ploting  only the New Deaths data
                ylabel(app.UIAxes, 'New deaths')
                ylim(app.UIAxes, [0, max(cell2mat(da_deaths))])
                ytickformat(app.UIAxes, '%d')
                app.UIAxes.YAxis.Exponent = 0;
                plot(app.UIAxes, datenum(app.Dates), cell2mat(da_deaths), 'r')
                
                return
                
            end                         
        end
        
        function changeData(app)
            % Getting usefull information
            country = app.CountryListBox.Value;
            state = app.StateListBox.Value;
            swt = app.OptionsSwitch.Value;
            avg = app.MovingAverageSpinner.Value;
            knob = app.PlotKnob.Value;
            
            if knob == "Both"
                % Selecting the New Cases database for the given country and state
                da_cases = app.Cases(strcmp(app.Cases(:, 1), country),  2:end);
                da_cases = da_cases(strcmp(da_cases(:, 1), state), 2:end);
            
                % Selecting the New Deaths database for the given country and state
                da_deaths = app.Deaths(strcmp(app.Deaths(:, 1), country),  2:end);
                da_deaths = da_deaths(strcmp(da_deaths(:, 1), state), 2:end);
                
                % If the switch is in the "Daily" position, we need to edit the database
                if swt == "Daily"
                    for ii = length(app.Dates):-1:2  
                        da_cases{ii} = da_cases{ii} - da_cases{ii - 1};
                        da_deaths{ii} = da_deaths{ii} - da_deaths{ii - 1};
                    end
                end
                
                da_cases = mat2cell(movmean(cell2mat(da_cases), avg), 1);
                da_deaths = mat2cell(movmean(cell2mat(da_deaths), avg), 1);
                
                app.PlaceCases = da_cases;
                app.PlaceDeaths = da_deaths;
                
                return
                
            elseif knob == "Cases"
                % Selecting the New Cases database for the given country and state
                da_cases = app.Cases(strcmp(app.Cases(:, 1), country),  2:end);
                da_cases = da_cases(strcmp(da_cases(:, 1), state), 2:end);
                
                % If the switch is in the "Daily" position, we need to edit the database
                if swt == "Daily"
                    for ii = length(app.Dates):-1:2  
                        da_cases{ii} = da_cases{ii} - da_cases{ii - 1};
                    end
                end
                
                da_cases = mat2cell(movmean(cell2mat(da_cases), avg), 1);
                
                app.PlaceCases = da_cases;
                
                return
                
            else  % i.e., knob == "Deaths"
                % Selecting the New Deaths database for the given country and state
                da_deaths = app.Deaths(strcmp(app.Deaths(:, 1), country),  2:end);
                da_deaths = da_deaths(strcmp(da_deaths(:, 1), state), 2:end);
                
                % If the switch is in the "Daily" position, we need to edit the database
                if swt == "Daily"
                    for ii = length(app.Dates):-1:2  
                        da_deaths{ii} = da_deaths{ii} - da_deaths{ii - 1};
                    end
                end
                    
                da_deaths = mat2cell(movmean(cell2mat(da_deaths), avg), 1);
                
                app.PlaceDeaths = da_deaths;
                
                return
                
                
            end          
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            db_cases = table2cell(readtable('new_cases.csv'));  % Much faster! 
            db_deaths = table2cell(readtable('new_deaths.csv'));
            % maybe use readtable?
            
            % Cleaning the db: It's not important to know Lat and Long (columns 3 and 4)
            db_cases = [db_cases(:, 2:-1:1), db_cases(:, 5:end)];
            db_deaths = [db_deaths(:, 2:-1:1), db_deaths(:, 5:end)];
                     
            % Modifying to add 'Global': 
            [rows, columns] = size(db_cases);  % It's the same for both
            new_line = ['Global', 'All', cell(1, columns-2)];
            db_cases = [db_cases(1, :); new_line; db_cases(2:end, :)];
            db_deaths = [db_deaths(1, :); new_line; db_deaths(2:end, :)];
            
            % Usefull relations:
            values = db_cases(1, :);
            countries_and_states = db_cases(2: end, 1:2);
            
            % Preallocating Memory:
            app.Cases = cell(rows + 1, columns);  % The + 1 to consider the Global (added before)
            app.Deaths = cell(rows + 1, columns);
            
            % Adding the values, countries and states to the other databases
            app.Cases(1, :) = values;
            app.Deaths(1, :) = values;
            app.Cases(2:end, 1:2) = countries_and_states;
            app.Deaths(2:end, 1:2) = countries_and_states;
            
            % Adding the values, countries and states to the other databases
            app.Cases(1, :) = values;
            app.Deaths(1, :) = values;
            app.Cases(2:end, 1:2) = countries_and_states;
            app.Deaths(2:end, 1:2) = countries_and_states;
            
            % Calculating the global values
            for jj = 3:columns
                acum_case = 0;  % Acumulator --> Will be used to calculate the global cases and deaths
                acum_deaths = 0;
                for ii = 3:rows
                    % Dumb way? For sure there is a better way to do this.
                    db_cases{ii, jj} = str2double(db_cases{ii, jj});
                    db_deaths{ii, jj} = str2double(db_deaths{ii, jj});
                    
                    acum_case = acum_case + db_cases{ii, jj};
                    acum_deaths = acum_deaths + db_deaths{ii, jj};
                    
                    app.Cases{ii, jj} = db_cases{ii, jj};
                    app.Deaths{ii, jj} = db_deaths{ii, jj};
                end
                db_cases{2, jj} = acum_case;
                db_deaths{2, jj} = acum_deaths;
                app.Cases{2, jj} = acum_case;
                app.Deaths{2, jj} = acum_deaths;
            end
            
            % Modifying to use 'All' instead of []
            db_cases(strcmp(db_cases(:, 2), ""), 2) = {'All'};
            db_deaths(strcmp(db_deaths(:, 2), ""), 2) = {'All'};
            app.Cases(strcmp(app.Cases(:, 2), ""), 2) = {'All'};
            app.Deaths(strcmp(app.Deaths(:, 2), ""), 2) = {'All'};
            
            % Setting the properties
            app.Dates = db_cases(1, 3:end);
            app.CountriesAndStates = db_cases(2:end, 1:2);
            
            % Editing the lists
            app.CountryListBox.Items = unique(db_cases(2:end, 1), 'stable');
            app.CountryListBox.Value = 'Global';
            app.StateListBox.Items = {'All'};  % This will be changed latter
            app.StateListBox.Value = 'All';
            
            % Using'Global' and 'All' as the standard values:
            da_cases = app.Cases(strcmp(app.Cases(:, 1), 'Global'),  2:end);
            da_cases = da_cases(strcmp(da_cases(:, 1), 'All'), 2:end);
            
            da_deaths = app.Deaths(strcmp(app.Deaths(:, 1), 'Global'),  2:end);
            da_deaths = da_deaths(strcmp(da_deaths(:, 1), 'All'), 2:end);
            
            app.PlaceCases = da_cases;
            app.PlaceDeaths = da_deaths;
            
            % Get the edited time 
            file = dir('new_cases.csv');
            t = file.datenum;
            update_time = string(datetime(t, "ConvertFrom", "datenum" ,"format", "dd/MM/yyyy HH:mm:ss"));
            app.UpdateLabel.Text = sprintf("Updated %s", update_time);
            
            app.plotData()         
        end

        % Value changed function: CountryListBox
        function CountryListBoxValueChanged(app, event)
            country = app.CountryListBox.Value;
            std_state = 'All';
            
            app.StateListBox.Items = app.CountriesAndStates(strcmp(app.CountriesAndStates(:, 1), country), 2);
            app.StateListBox.Value = std_state;
                        
            app.changeData()          
            
            app.plotData()
        end

        % Value changed function: StateListBox
        function StateListBoxValueChanged(app, event)
            app.changeData()
            
            app.plotData()
        end

        % Value changed function: OptionsSwitch
        function OptionsSwitchValueChanged(app, event)
            app.changeData()
            
            app.plotData()
        end

        % Value changed function: PlotKnob
        function PlotKnobValueChanged(app, event)
            app.changeData()
            
            app.plotData()
        end

        % Value changed function: MovingAverageSpinner
        function MovingAverageSpinnerValueChanged(app, event)
            app.changeData()
            
            app.plotData()            
        end

        % Button pushed function: UpdateDatabaseButton
        function UpdateDatabaseButtonPushed(app, event)
            app.UpdateLabel.Text = "Loading...";  % Change the text displayed next to the button to "Loading..."
            % Get the URL of the db 
            new_cases_url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv';
            new_deaths_url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv';
            % Save the files
            websave('new_cases.csv', new_cases_url); 
            websave('new_deaths.csv', new_deaths_url);
            % We call the startupFcn to restart the app 
            startupFcn(app)  
            % Getting Time
            t = now;
            update_time = string(datetime(t, "ConvertFrom", "datenum" ,"format", "dd/MM/yyyy HH:mm:ss"));
            app.UpdateLabel.Text = sprintf("Updated %s", update_time);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create CovidVisualizationAppUIFigure and hide until all components are created
            app.CovidVisualizationAppUIFigure = uifigure('Visible', 'off');
            app.CovidVisualizationAppUIFigure.Position = [100 100 780 550];
            app.CovidVisualizationAppUIFigure.Name = 'Covid Visualization App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.CovidVisualizationAppUIFigure);
            title(app.UIAxes, 'Loading...')
            xlabel(app.UIAxes, 'Date')
            ylabel(app.UIAxes, '')
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Position = [19 290 744 246];

            % Create CountryListBoxLabel
            app.CountryListBoxLabel = uilabel(app.CovidVisualizationAppUIFigure);
            app.CountryListBoxLabel.HorizontalAlignment = 'right';
            app.CountryListBoxLabel.FontWeight = 'bold';
            app.CountryListBoxLabel.Position = [19 242 51 22];
            app.CountryListBoxLabel.Text = 'Country';

            % Create CountryListBox
            app.CountryListBox = uilistbox(app.CovidVisualizationAppUIFigure);
            app.CountryListBox.Items = {'Loading...', ''};
            app.CountryListBox.ValueChangedFcn = createCallbackFcn(app, @CountryListBoxValueChanged, true);
            app.CountryListBox.Position = [85 18 150 246];
            app.CountryListBox.Value = {};

            % Create StateListBoxLabel
            app.StateListBoxLabel = uilabel(app.CovidVisualizationAppUIFigure);
            app.StateListBoxLabel.HorizontalAlignment = 'right';
            app.StateListBoxLabel.FontWeight = 'bold';
            app.StateListBoxLabel.Position = [252 242 35 22];
            app.StateListBoxLabel.Text = 'State';

            % Create StateListBox
            app.StateListBox = uilistbox(app.CovidVisualizationAppUIFigure);
            app.StateListBox.Items = {'Loading...', ''};
            app.StateListBox.ValueChangedFcn = createCallbackFcn(app, @StateListBoxValueChanged, true);
            app.StateListBox.Position = [302 18 150 244];
            app.StateListBox.Value = {};

            % Create MovingAverageSpinnerLabel
            app.MovingAverageSpinnerLabel = uilabel(app.CovidVisualizationAppUIFigure);
            app.MovingAverageSpinnerLabel.HorizontalAlignment = 'right';
            app.MovingAverageSpinnerLabel.FontWeight = 'bold';
            app.MovingAverageSpinnerLabel.Position = [494 242 98 22];
            app.MovingAverageSpinnerLabel.Text = 'Moving Average';

            % Create MovingAverageSpinner
            app.MovingAverageSpinner = uispinner(app.CovidVisualizationAppUIFigure);
            app.MovingAverageSpinner.Limits = [1 15];
            app.MovingAverageSpinner.RoundFractionalValues = 'on';
            app.MovingAverageSpinner.ValueChangedFcn = createCallbackFcn(app, @MovingAverageSpinnerValueChanged, true);
            app.MovingAverageSpinner.Position = [607 242 156 22];
            app.MovingAverageSpinner.Value = 1;

            % Create OptionsSwitchLabel
            app.OptionsSwitchLabel = uilabel(app.CovidVisualizationAppUIFigure);
            app.OptionsSwitchLabel.HorizontalAlignment = 'center';
            app.OptionsSwitchLabel.FontWeight = 'bold';
            app.OptionsSwitchLabel.Position = [504 203 51 22];
            app.OptionsSwitchLabel.Text = 'Options';

            % Create OptionsSwitch
            app.OptionsSwitch = uiswitch(app.CovidVisualizationAppUIFigure, 'slider');
            app.OptionsSwitch.Items = {'Culmulative', 'Daily'};
            app.OptionsSwitch.Orientation = 'vertical';
            app.OptionsSwitch.ValueChangedFcn = createCallbackFcn(app, @OptionsSwitchValueChanged, true);
            app.OptionsSwitch.Position = [515 111 29 66];
            app.OptionsSwitch.Value = 'Culmulative';

            % Create PlotKnobLabel
            app.PlotKnobLabel = uilabel(app.CovidVisualizationAppUIFigure);
            app.PlotKnobLabel.HorizontalAlignment = 'center';
            app.PlotKnobLabel.FontWeight = 'bold';
            app.PlotKnobLabel.Position = [669 203 28 22];
            app.PlotKnobLabel.Text = 'Plot';

            % Create PlotKnob
            app.PlotKnob = uiknob(app.CovidVisualizationAppUIFigure, 'discrete');
            app.PlotKnob.Items = {'Cases', 'Both', 'Deaths'};
            app.PlotKnob.ValueChangedFcn = createCallbackFcn(app, @PlotKnobValueChanged, true);
            app.PlotKnob.Position = [655 110 60 60];
            app.PlotKnob.Value = 'Both';

            % Create UpdateDatabaseButton
            app.UpdateDatabaseButton = uibutton(app.CovidVisualizationAppUIFigure, 'push');
            app.UpdateDatabaseButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateDatabaseButtonPushed, true);
            app.UpdateDatabaseButton.Position = [475 34 109 22];
            app.UpdateDatabaseButton.Text = 'Update Database';

            % Create UpdateLabel
            app.UpdateLabel = uilabel(app.CovidVisualizationAppUIFigure);
            app.UpdateLabel.Position = [591 34 172 22];
            app.UpdateLabel.Text = 'Loading...';

            % Show the figure after all components are created
            app.CovidVisualizationAppUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CovidVisualizationApp

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.CovidVisualizationAppUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.CovidVisualizationAppUIFigure)
        end
    end
end