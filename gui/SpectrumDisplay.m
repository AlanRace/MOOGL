classdef SpectrumDisplay < Display
    properties (SetAccess = protected)
        % Handle for either the bar or line plot
        plotHandle;
        
        peakList;
        peakDetails;
        peakHeight;
    end
    
    properties (Access = protected)
        % Variable used to determine if we are in zoom mode
        zoomingIn = 0;
        aboveAxis = 0;
        
        xLimit;
        yLimit;
        
        startPoint;
        currentPoint;
        currentLine;
        leftMouseDown = 0;
        
        peakDetectionMethod;
        
        peakDetectionMethods;
        peakDetectionMenuItem;
        
        peakFilterListEditor;
        
        continuousDisplay;
    end
    
    events
        PeakSelected;
    end
    
    methods
        function obj = SpectrumDisplay(parent, spectrum)
            obj = obj@Display(parent, spectrum);
            
            if(~isa(spectrum, 'SpectralData'))
                exception = MException('SpectrumDisplay:invalidArgument', 'Must provide an instance of a class that extends SpectralData');
                throw(exception);
            end
            
            % Set up the mouse motion and button callbacks for zooming
            addlistener(parent, 'ButtonDown', @(src, evnt)obj.buttonDownCallback());
            addlistener(parent, 'ButtonMotion', @(src,evnt)obj.mouseMovedCallback());
            addlistener(parent, 'ButtonUp', @(src, evnt)obj.mouseButtonUpCallback());
        end
        
        function createContextMenu(obj)
            createContextMenu@Display(obj);
            
            uimenu(obj.exportMenu, 'Label', 'To CSV', 'Callback', @(src, evnt)obj.exportToCSV());
            
            % Checks if getSubclasses is on the path, if so likely to be
            % SpectralAnalysis running, so add in the peak detection menu
            % automatically
            % TODO: Have a better way of automatically adding the peak
            % picking menu, or move the menu elsewhere in the interface
            if(exist('getSubclasses', 'file'))
                [peakDetectionMethods, classNames] = getSubclasses('SpectralPeakDetection', 1);
                
                obj.addPeakDetectionMenu(peakDetectionMethods, classNames);
            end
            
            obj.continuousDisplay = uimenu(obj.contextMenu, 'Label', 'Continuous Display', 'Checked', 'on', 'Callback', @(src, evnt)obj.switchContinuousDisplay());
        end
        
        function switchContinuousDisplay(this)
            % switchContinuousDisplay Toggle the display between continuous and discrete.
            %
            %   switchContinuousDisplay()
            
            isContinuous = get(this.continuousDisplay, 'Checked');
            
            if(strcmp(isContinuous, 'on'))
                set(this.continuousDisplay, 'Checked', 'off');
            else
                set(this.continuousDisplay, 'Checked', 'on');
            end
            
            this.updateDisplay();
        end
        
        function addPeakDetectionMenu(obj, peakDetectionMethods, classNames)
            % switchContinuousDisplay Toggle the display between continuous and discrete.
            %
            %   switchContinuousDisplay()
            
            labelPeaks = uimenu(obj.contextMenu, 'Label', 'Label Peaks', 'Separator', 'on');
            
            obj.peakDetectionMethods = peakDetectionMethods;
            
            for i = 1:length(classNames)
                obj.peakDetectionMenuItem(i) = uimenu(labelPeaks, 'Label', classNames{i}, 'Callback', @(src, evnt)obj.labelPeaksWithMethod(i));
            end
            
            set(obj.peakDetectionMenuItem(1), 'Checked', 'on');
        end
        
        function exportToCSV(obj)
            [FileName,PathName,FilterIndex] = uiputfile('*.csv', 'Save spectrum as', 'spectrum.csv');
            
            if(FilterIndex == 1)
                size(obj.peakList)
                if(isempty(obj.peakList) || isempty(obj.peakHeight))
                    peakList = obj.data.spectralChannels;
                    peakHeight = obj.data.intensities;
                else
                    peakList = obj.peakList;
                    peakHeight = obj.peakHeight;
                end
                %                 size(peakList)
                try
                    decimalSeparator = java.text.DecimalFormat().getDecimalFormatSymbols().getDecimalSeparator();
                    
                    % Check to see if the computer is set to use German
                    % deceimal separators
                    if(strcmp(decimalSeparator, ','))
                        decimalSeparator = ',';
                        csvSeparator = ';';
                    else
                        decimalSeparator = '.';
                        csvSeparator = ',';
                    end
                    
                    fid = fopen([PathName filesep FileName], 'w');
                    
                    for i = 1:length(peakList)
                        fprintf(fid, strrep(strrep(sprintf('%0.10f%s%0.10f\n', peakList(i), '#', peakHeight(i)), '.', decimalSeparator), '#', csvSeparator));
                    end
                    
                    fclose(fid);
%                     dlmwrite([PathName filesep FileName], [peakList' peakHeight'], 'precision', 16);
                catch err
                    msgbox(err.message, err.identifier);
                    err
                end
            end
        end
        
        function setData(obj, spectrum)
            obj.xLimit = [min(spectrum.spectralChannels) max(spectrum.spectralChannels)];
            obj.yLimit = [min(spectrum.intensities) max(spectrum.intensities)];
            
            setData@Display(obj, spectrum);
            
            % If peak picking is on then make sure we peak pick on the new
            % spectrum
            if(~isempty(obj.peakDetectionMethod))
                obj.updatePeakDetection();
            end
            
            %             if(~isempty(obj.peakDetectionMenuItem))
            %                 peakDetectionMethod = 1;
            %                 for i = 1:length(obj.peakDetectionMenuItem)
            %                     if(strcmp(get(obj.peakDetectionMenuItem(i), 'Checked'), 'on'))
            %                         peakDetectionMethod = i;
            %                     end
            %                 end
            %
            %                 obj.labelPeaksWithMethod(peakDetectionMethod);
            %             end
        end
        
        function xLimit = getXLimit(obj)
            xLimit = obj.xLimit;
        end
        
        function yLimit = getYLimit(obj)
            yLimit = obj.yLimit;
        end
        
        function setXLimit(obj, xLimit)
            obj.xLimit = xLimit;
            obj.updateDisplay();
        end
        
        function setYLimit(obj, yLimit)
            obj.yLimit = yLimit;
            obj.updateDisplay();
        end
        
        function labelPeaksWithMethod(obj, index)
            for i = 1:length(obj.peakDetectionMenuItem)
                try
                    set(obj.peakDetectionMenuItem(i), 'Checked', 'off');
                catch err
                    % Do nothing, happens if the peak detection menu item
                    % no longer exists
                end
            end
            
            try
                set(obj.peakDetectionMenuItem(index), 'Checked', 'on');
            catch err
                % Do nothing, happens if the peak detection menu item
                % no longer exists
            end
            
            if(index > 1)
                obj.peakDetectionMethod = eval([obj.peakDetectionMethods{index} '()']);
                
                if(isa(obj.peakFilterListEditor, 'PeakFilterListEditor') && isvalid(obj.peakFilterListEditor))
                    figure(obj.peakFilterListEditor.figureHandle);
                else
                    obj.peakFilterListEditor = PeakFilterListEditor(obj.data, obj.peakDetectionMethod);
                    addlistener(obj.peakFilterListEditor, 'FinishedEditing', @(src, evnt)obj.updatePeakDetection());
                end
            else
                obj.peakDetectionMethod = [];
                
                obj.peakList = [];
                obj.peakHeight = [];
                obj.peakDetails = [];
            end
            
            obj.updateDisplay();
        end
        
        function setPeakDetection(obj, peakDetection)
            obj.peakDetectionMethod = peakDetection;
            
            obj.updatePeakDetection();
        end
        
        function updatePeakDetection(obj)
            [obj.peakList, obj.peakHeight, obj.peakDetails] = obj.peakDetectionMethod.process(obj.data.spectralChannels, obj.data.intensities);
            
            assignin('base', 'peakDetails', obj.peakDetails);
            
            obj.updateDisplay();
        end
                
        function display = openInNewWindow(obj)
            % openInNewWindow Opens the spectral data in a new window.
            %
            %   openInNewWindow()
            %
            %   Open the spectral data in a new window with same display 
            %   options applied. Any changes made the the underlying 
            %   spectrum will be updated in the new display too.
            
            figure = Figure;
            figure.showStandardFigure();
            
            spectrumPanel = SpectrumPanel(figure, obj.data);
            
            display = spectrumPanel.spectrumDisplay;
            display.updateDisplay();
        end
        
        function display = openCopyInNewWindow(obj)
            % openCopyInNewWindow Opens a copy of the spectral data in a new window.
            %
            %   openCopyInNewWindow()
            %
            %   Open a copy of the spectral data in a new window so that if 
            %   any changes are made to the spectrum in this display they 
            %   aren't updated in the new display.
        
            
            figure = Figure;
            figure.showStandardFigure();
            
            spectrumPanel = SpectrumPanel(figure, SpectralData(obj.data.spectralChannels, obj.data.intensities));
            
            display = spectrumPanel.spectrumDisplay;
            display.updateDisplay();
        end
        
        
        function exportToImage(obj)
            [fileName, pathName, filterIndex] = uiputfile([obj.lastSavedPath 'spectrum.pdf'], 'Export image');
            
            if(filterIndex > 0)
                obj.lastSavedPath = [pathName filesep];
                
                f = figure('Visible', 'off');
                axisHandle = axes;
                normPos = get(axisHandle, 'Position');
                delete(axisHandle);
                %                 display = SpectrumDisplay(axisHandle, obj.data);
                %
                % %                 display.copy(obj);
                %
                %                 set(axisHandle, 'Color', 'none');
                %                 set(f, 'Color', 'none');
                %
                %                 set(axisHandle, 'XLim', obj.xLimit);
                %                 set(axisHandle, 'YLim', obj.yLimit);
                
                newAxis = copyobj(obj.axisHandle, f);
                
                % Fix aspect ratio
                pos = get(newAxis, 'Position');
                aspectRatio = pos(4) / pos(3);
                set(newAxis, 'Position', normPos);
                
                posOfFigure = get(f, 'PaperPosition');
                posOfFigure(1) = 0;
                posOfFigure(2) = 0;
                posOfFigure(4) = round(posOfFigure(3) * aspectRatio / 1.5);
                set(f, 'PaperSize', [posOfFigure(3) posOfFigure(4)]);
                set(f, 'PaperPosition', posOfFigure);
                set(f, 'PaperPositionMode', 'manual');
                %                 set(f, 'PaperOrientation', 'landscape');
                
                %                 get(f)
                
                print(f, [pathName filesep fileName], '-dpdf', '-painters', '-r0');% test.pdf
                
                %                 export_fig(f, [pathName filesep fileName], '-painters', '-transparent');
                delete(f);
            end
        end
        
        function exportToLaTeX(obj)
        end
        
        function updateDisplay(obj)
            %             xLimit = get(obj.axisHandle, 'xLim');
            %             yLimit = get(obj.axisHandle, 'yLim');
            
            obj.plotSpectrum();
            
            obj.fixLimits();
            obj.updateLimits();
            
            if(~isempty(obj.peakList))
                %                 if(xLimit ~= [0 1])
                indicies = obj.peakList >= obj.xLimit(1) & obj.peakList <= obj.xLimit(2);
                
                peakList = obj.peakList(indicies);
                peakHeight = obj.peakHeight(indicies);
                
                yPos = ((obj.yLimit(2) - obj.yLimit(1)) * 0.95) + obj.yLimit(1);
                
                text(obj.xLimit(1), yPos, ['Detected peaks: ' num2str(length(obj.peakList))], 'Parent', obj.axisHandle);
                %                 else
                %                     peakList = obj.peakList;
                %                     peakHeight = obj.peakHeight;
                %
                %                     yPos = ((max(obj.data.intensities) - min(obj.data.intensities)) * 0.95) + min(obj.data.intensities);
                %
                %                     text(min(obj.data.spectralChannels), yPos, ['Detected peaks: ' num2str(length(obj.peakList))], 'Parent', obj.axisHandle);
                %                 end
                
                [m, indicies] = sort(peakHeight, 'descend');
                
                for i = 1:min(10, length(peakList))
                    text(peakList(indicies(i)), peakHeight(indicies(i)), num2str(peakList(indicies(i))), 'Parent', obj.axisHandle);
                end
            end
            %            warning('TODO: Display any detected peaks avoiding textual overlap');
            
            % Set up callback functions such as button down functions
            set(obj.plotHandle, 'ButtonDownFcn', @(src, evnt)obj.buttonDownCallback());
            set(obj.axisHandle, 'ButtonDownFcn', @(src, evnt)obj.buttonDownCallback());
            
            if(~isempty(obj.contextMenu))
                set(obj.axisHandle, 'UIContextMenu', obj.contextMenu);
            end
            
            % Ensure that notifications are made that the display has
            % changed
            updateDisplay@Display(obj);
        end
        
        function mouseMovedCallback(obj)
            obj.deleteLine();
            
            %             xLimit = get(obj.axisHandle, 'XLim');
            %             yLimit = get(obj.axisHandle, 'YLim');
            
            if(obj.leftMouseDown)
                axes(obj.axisHandle);
                
                currentPoint = get(obj.axisHandle, 'CurrentPoint');
                obj.currentPoint = [currentPoint(1, 1) currentPoint(1, 2)];
                
                if(obj.aboveAxis == 1 && obj.data.isContinuous)
                    obj.currentLine = line([obj.startPoint(1) obj.currentPoint(1)], [obj.startPoint(2) obj.startPoint(2)], 'Color', [0 1 0]);
                elseif(obj.zoomingIn == 2)
                    if(~isempty(obj.xLimit))
                        xMidPoint = ((obj.xLimit(2)-obj.xLimit(1))/2)+obj.xLimit(1);
                        obj.currentLine = line([xMidPoint xMidPoint], [obj.startPoint(2) obj.currentPoint(2)], 'Color', [1 0 0]);
                    end
                elseif(obj.zoomingIn == 1)
                    if(~isempty(obj.yLimit))
                        yMidPoint = ((obj.yLimit(2)-obj.yLimit(1))/2)+obj.yLimit(1);
                        obj.currentLine = line([obj.startPoint(1) obj.currentPoint(1)], [yMidPoint yMidPoint], 'Color', [1 0 0]);
                    end
                end
            end
        end
        
        
        
        function mouseButtonUpCallback(obj)
            obj.leftMouseDown = 0;
            
            if(~isempty(obj.startPoint))
                isNotSamePoint = ~(isequal(obj.startPoint(1), obj.currentPoint(1)) && isequal(obj.startPoint(2), obj.currentPoint(2)));
                
                currentPoint = get(obj.axisHandle, 'CurrentPoint');
                
                if(~isempty(obj.continuousDisplay) && isvalid(obj.continuousDisplay))
                    isContinuous = strcmp(get(obj.continuousDisplay, 'Checked'), 'on');
                else
                    isContinuous = true;
                end
                
                if((~isNotSamePoint && obj.aboveAxis == 1 && ~isContinuous)) % || (~obj.data.isContinuous && obj.aboveAxis == 1))
                    obj.mouseClickInsideAxis();
                    
                    [minVal, minLoc] = min(abs(obj.data.spectralChannels - currentPoint(1)));
                    minVal = obj.data.spectralChannels(minLoc);
                    
                    peakSelectionEvent = PeakSelectionEvent(PeakSelectionEvent.Exact, minVal); % currentPoint(1));
                    notify(obj, 'PeakSelected', peakSelectionEvent);
                    
                    %                     mouseEvent = MouseEventData(MouseEventData.ButtonDown, obj.currentPoint(1), obj.currentPoint(2));
                    %
                    %                     notify(obj, 'MouseClickInsideAxis', mouseEvent);
                else
                    if(obj.aboveAxis ~= 0 && isNotSamePoint) % && obj.data.isContinuous)
                        obj.deleteLine();
                        
                        xPoint = currentPoint(1, 1);
                        yPoint = currentPoint(1, 2);
                        
                        obj.aboveAxis = 0;
                        
                        peakRange = [obj.startPoint(1) xPoint];
                        peakRange = sort(peakRange, 'ascend');
                        
                        peakSelectionEvent = PeakSelectionEvent(PeakSelectionEvent.Range, peakRange);
                        notify(obj, 'PeakSelected', peakSelectionEvent);
                        
                        %                         mouseEvent = MouseEventData(MouseEventData.ButtonDown, xPoint, yPoint);
                        %                         notify(obj, 'MouseUpInsideAxis', mouseEvent);
                    elseif(obj.zoomingIn ~= 0 && isNotSamePoint)
                        obj.deleteLine();
                        
                        %                     xLimit = get(obj.axisHandle, 'XLim');
                        %                     yLimit = get(obj.axisHandle, 'YLim');
                        
                        if(obj.zoomingIn == 1)
                            %                         set(obj.axisHandle, 'XLim', sort([obj.startPoint(1) obj.currentPoint(1)], 'ascend'));
                            %                         set(obj.axisHandle, 'YLim', yLimit);
                            obj.xLimit = sort([obj.startPoint(1) obj.currentPoint(1)], 'ascend');
                            obj.yLimit = [];
                        else
                            %                         set(obj.axisHandle, 'YLim', sort([obj.startPoint(2) obj.currentPoint(2)], 'ascend'));
                            %                         set(obj.axisHandle, 'XLim', xLimit);
                            obj.yLimit = sort([obj.startPoint(2) obj.currentPoint(2)], 'ascend');
                        end
                        
                        obj.updateDisplay();
                    end
                end
            end
            
            obj.aboveAxis = 0;
            obj.zoomingIn = 0;
        end
    end
    
    methods (Access = protected)
        
        function plotSpectrum(this)
            % Check if the continuousDisplay (tick box in the context menu)
            % has been assigned and is still valid, otherwise default to
            % continuous data
            if(~isempty(this.continuousDisplay) && isvalid(this.continuousDisplay))
                isContinuous = strcmp(get(this.continuousDisplay, 'Checked'), 'on');
            else
                isContinuous = true;
            end
            
            % If the display is set to continuous, then plot with 'plot'
            % otherwise use 'bar'
            if(~isContinuous)
                % Ensure that an edge colour is applied to the bar so that
                % it is visualised correctly in MATLAB R2016+
                this.plotHandle = bar(this.axisHandle, this.data.spectralChannels, this.data.intensities, 'k', 'EdgeColor', [0 0 0]);
            else
                this.plotHandle = plot(this.axisHandle, this.data.spectralChannels, this.data.intensities);
            end
        end
        
        function fixLimits(this)
            if(isempty(this.xLimit))
                if(isempty(min(this.data.spectralChannels)) || isempty(max(this.data.spectralChannels)))
                    this.xLimit = [0 1];
                else
                    this.xLimit = [min(this.data.spectralChannels) max(this.data.spectralChannels)];
                end
            end
            
            if(isempty(this.yLimit))
                currentViewMask = this.data.spectralChannels >= this.xLimit(1) & this.data.spectralChannels <= this.xLimit(2);
                
                this.yLimit = [min(this.data.intensities(currentViewMask)) max(this.data.intensities(currentViewMask))];
            end
        end
        
        function updateLimits(this)
            % Ensure that the limits are increasing and not empty
            if(isempty(this.xLimit) || isequal(this.xLimit, [0 0]))
                this.xLimit = [0 1];
            end
            if(isempty(this.yLimit) || isequal(this.yLimit, [0 0]) || max(isnan(this.yLimit) == 1))
                this.yLimit = [0 1];
            end
            
            if(this.xLimit(2) < this.xLimit(1) || this.xLimit(1) == this.xLimit(2))
                return;
            end
            if(this.yLimit(2) < this.yLimit(1) || this.yLimit(1) == this.yLimit(2))
                return;
            end
            
            set(this.axisHandle, 'xLim', this.xLimit);
            set(this.axisHandle, 'yLim', this.yLimit);
        end
        
        
        function deleteLine(obj)
            if(~isempty(obj.currentLine))
                try
                    delete(obj.currentLine);
                catch err
                    warning('TODO: Handle error')
                end
                
                obj.currentLine = [];
            end
        end
        
        function mouseClickInsideAxis(obj)
            %TODO: Fit to peak
            
        end
        
        function buttonDownCallback(obj)
            currentPoint = get(obj.axisHandle, 'CurrentPoint');
            
            %             xLimit = get(obj.axisHandle, 'xLim');
            %             yLimit = get(obj.axisHandle, 'yLim');
            
            xPoint = currentPoint(1, 1);
            yPoint = currentPoint(1, 2);
            
            figureHandle = obj.parent.getParentFigure().handle;
            
            mouseClick = get(figureHandle, 'SelectionType');
            
            if(strcmp(mouseClick, 'normal')) % Left click
                obj.startPoint = [xPoint yPoint];
                obj.currentPoint = obj.startPoint;
                obj.leftMouseDown = 1;
            end
            
            % Ensure that we are below the x-axis, otherwise call the above
            % axis dragging function
            if(xPoint > obj.xLimit(1) && yPoint > obj.yLimit(1))
                if(strcmp(mouseClick, 'normal'))
                    obj.aboveAxis = 1;
                end
                
                %                 mouseEvent = MouseEventData(MouseEventData.ButtonDown, xPoint, yPoint);
                %
                %                 notify(obj, 'MouseDownInsideAxis', mouseEvent);
            else
                if(currentPoint(1, 1) < obj.xLimit(1))
                    obj.zoomingIn = 2;
                else
                    obj.zoomingIn = 1;
                end
                
                if(strcmp(mouseClick, 'open')) % Double left click
                    obj.zoomingIn = 0;
                    
                    if(currentPoint(1, 1) < obj.xLimit(1))
                        %                         ylim('auto');
                        currentIntensities = obj.data.intensities(obj.data.spectralChannels >= obj.xLimit(1) & obj.data.spectralChannels <= obj.xLimit(2));
                        obj.yLimit = [min(currentIntensities) max(currentIntensities)];
                    end
                    if(isempty(obj.yLimit) || currentPoint(2, 2) < obj.yLimit(1))
                        %                         xlim('auto');
                        obj.xLimit = [min(obj.data.spectralChannels) max(obj.data.spectralChannels)];
                        obj.yLimit = [];
                    end
                    
                    obj.updateDisplay();
                end
            end
        end
    end
end