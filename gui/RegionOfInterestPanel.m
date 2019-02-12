classdef RegionOfInterestPanel < Panel
    properties (SetAccess = protected)
        regionOfInterestList;
        
        regionOfInterestTable;
        editRegionOfInterestButton;
        saveRegionOfInterestButton;
        loadRegionOfInterestButton;
        infoRegionOfInterestButton;
        selectedROIs;
        
        regionOfInterestListEditor;
        
        roiListListener;
        
        imageForEditor;
        
        lastPath;
    end
    
    events
        RegionOfInterestListChanged
        RegionOfInterestSelected
        InfoButtonClicked
    end
    
    methods
        function this = RegionOfInterestPanel(parent)
            this = this@Panel(parent);
            
            this.regionOfInterestList = RegionOfInterestList();
            this.roiListListener = addlistener(this.regionOfInterestList, 'ListChanged', @(src, event) notify(this, 'RegionOfInterestListChanged', event));
            
            this.imageForEditor = Image(1);
        end
        
        
        function setRegionOfInterestList(this, regionOfInterestList)
            this.regionOfInterestList = regionOfInterestList;
            
            if(~isempty(this.roiListListener))
                delete(this.roiListListener);
            end
            
            this.roiListListener = addlistener(regionOfInterestList, 'ListChanged', @(src, event) notify(this, 'RegionOfInterestListChanged', event));
            
            this.updateRegionOfInterestList();
        end
        
        function setImageForEditor(this, image)
            this.imageForEditor = image;
            image
        end
    end
    
    methods
        
    end
    
    methods(Access = protected)   
        function editRegionOfInterestList(this)
            % Check if we have already opened the
            % RegionOfInterestListEditor and if so if it is still a valid
            % instance of the class. If so show it, otherwise recreate it
            if(isa(this.regionOfInterestListEditor, 'RegionOfInterestListEditor') && isvalid(this.regionOfInterestListEditor))
                figure(this.regionOfInterestListEditor.handle);
            else
                this.regionOfInterestListEditor = RegionOfInterestListEditor(this.imageForEditor, this.regionOfInterestList);

                addlistener(this.regionOfInterestListEditor, 'FinishedEditing', @(src, evnt)this.finishedEditingRegionOfInterestList());
            end
            
            assignin('base', 'dvroiList', this.regionOfInterestList);
        end
        
        function selectRegionOfInterest(this, src, event)
             this.selectedROIs = event.Indices(:, 1)';
             
             notify(this, 'RegionOfInterestSelected', event);
        end
        
        function finishedEditingRegionOfInterestList(this)
            this.regionOfInterestList = this.regionOfInterestListEditor.regionOfInterestList;
            notify(this, 'RegionOfInterestListChanged')
            
            this.updateRegionOfInterestList();
        end
        
        function saveRegionOfInterest(this)
            % Get the fiter specification of the parser
            filterSpec = {'*.rois', 'ROI List (*.rois)'};
                       
            % Show file select interface
            [fileName, pathName, filterIndex] = uiputfile(filterSpec, 'Save ROI List', this.lastPath);
            
            % Check that the Open dialog was not cancelled
            if(filterIndex > 0)
                % Update the last path so that next time we open a file we
                % start where we left off
                this.lastPath = pathName;
                
                fid = fopen([pathName filesep fileName], 'w');
                this.regionOfInterestList.outputXML(fid, 0);
                fclose(fid);
            end
%             this.regionOfInterestList.get(1)
%             for i = this.selectedROIs
%                 variableName = inputdlg(['Please specifiy a variable name for ' this.regionOfInterestList.get(i).name ':'], 'Variable name', 1, {'roi'});
% 
%                 while(~isempty(variableName))
%                     if(isvarname(variableName{1}))
%                         assignin('base', variableName{1}, this.regionOfInterestList.get(i));
%                         break;
%                     else
%                         variableName = inputdlg('Invalid variable name. Please specifiy a variable name:', 'Variable name', 1, variableName);
%                     end
%                 end
%             end
        end
        
        function loadRegionOfInterest(this)
            filterSpec = {'*.rois', 'ROI List (*.rois)'};
                       
            % Show file select interface
            [fileName, pathName, filterIndex] = uigetfile(filterSpec, 'Load ROI List', this.lastPath);
            
            % Check that the Open dialog was not cancelled
            if(filterIndex > 0)
                % Update the last path so that next time we open a file we
                % start where we left off
                this.lastPath = pathName;
                
                regionOfInterestList = parseRegionOfInterestList([pathName filesep fileName]);
                
%                 if(regionOfInterestList.getSize() > 0)                
%                     newROI = regionOfInterestList.get(1);
%                     
%                     if(newROI.width == size(this.imageForEditor, 2) && newROI.height == size(this.imageForEditor, 1))
                        this.regionOfInterestList.addAll(regionOfInterestList);

                        this.updateRegionOfInterestList();
%                     else
%                         roiListSize = ['(' num2str(size(this.imageForEditor, 2)) ', ' num2str(size(this.imageForEditor, 1)) ')'];
%                         expectedSize = ['(' num2str(newROI.width) ', ' num2str(newROI.height) ')'];
%                         
%                         exception = MException('RegionOfInterestPanel:invalidROIList', ['ROIs are of a different size than expected ' expectedSize ' but got ' roiListSize] );
%                         
%                         % Make sure the user sees that we have had an error
%                         errordlg(exception.message, exception.identifier);
%                         throw(exception);
%                     end
%                 end
            end
%             variables = evalin('base', 'who');
%             rois = {};
%             
%             for i = 1:length(variables)
%                 if(evalin('base', ['isa(' variables{i} ', ''RegionOfInterest'')']) || ...
%                         evalin('base', ['isa(' variables{i} ', ''RegionOfInterestList'')']))
%                 
%                     rois{end+1} = variables{i};
%                 end
%             end
%             
%             if(isempty(rois))
%                 msgbox('No RegionOfInterest or RegionOfInterestList found in the workspace', 'No ROIs to load');
%             else
%                 [selection, ok] = listdlg('PromptString', 'Select ROI(s)', ...
%                     'ListString', rois);
% 
%                 if(ok)
%                     for i = selection
%                         newROI = evalin('base', rois{i});
% 
%                         if(isa(newROI, 'RegionOfInterest'))
%                             this.regionOfInterestList.add(newROI);
%                         elseif(isa(newROI, 'RegionOfInterestList'))
%                             for j = 1:newROI.getSize()
%                                 this.regionOfInterestList.add(newROI.get(j));
%                             end
%                         end
%                     end
% 
%                     this.updateRegionOfInterestList();
%                 end
%             end
        end
                
        function updateRegionOfInterestList(this)
            rois = this.regionOfInterestList.getObjects();
            data = {};
            
            for i = 1:numel(rois)
                data{i, 1} = ['<HTML><font color="' rois{i}.getColour().toHex() '">' rois{i}.getName() '</font></HTML>' ];
                data{i, 2} = false;
            end
            
            set(this.regionOfInterestTable, 'Data', data);
            
%             this.updateRegionOfInterestDisplay();
        end
        
        function createPanel(this)
            createPanel@Panel(this);
            
            %Set up the region of interest table
                columnNames = {'Region', 'Display'};
                columnFormat = {'char', 'logical'};
                columnEditable = [false, true];
                
                this.regionOfInterestTable = uitable('Parent', this.handle, ...
                    'ColumnName', columnNames, 'ColumnFormat', columnFormat, 'ColumnEditable', columnEditable, ...
                    'RowName', [], 'CellEditCallback', @(src, evnt) notify(this, 'RegionOfInterestSelected'), ...
                    'CellSelectionCallback', @this.selectRegionOfInterest, ...
                    'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.9]);
                this.editRegionOfInterestButton = uicontrol('Parent', this.handle, 'String', 'Edit', ...
                    'Units', 'normalized', 'Position', [0.65 0.1 0.3 0.3], 'Callback', @(src, evnt)this.editRegionOfInterestList(), ...
                    'TooltipString', 'Add/Edit regions of interest');
                this.saveRegionOfInterestButton = uicontrol('Parent', this.handle, 'String', 'S', ...
                    'Units', 'normalized', 'Position', [0.1 0.1 0.1 0.3], 'Callback', @(src, evnt)this.saveRegionOfInterest(), ...
                    'TooltipString', 'Save region of interest list');
                this.loadRegionOfInterestButton = uicontrol('Parent', this.handle, 'String', 'L', ...
                    'Units', 'normalized', 'Position', [0.1 0.1 0.1 0.05], 'Callback', @(src, evnt)this.loadRegionOfInterest(), ...
                    'TooltipString', 'Load region of interest list');
                this.infoRegionOfInterestButton = uicontrol('Parent', this.handle, 'String', 'i', ...
                    'Units', 'normalized', 'Position', [0.1 0.1 0.1 0.05], 'Callback', @(src, evnt)notify(this, 'InfoButtonClicked'), ...
                    'TooltipString', 'Display region of interest details');
        end
        
        function sizeChanged(this)
            oldUnits = get(this.handle, 'Units');
            set(this.handle, 'Units', 'pixels');
            
            panelPosition = get(this.handle, 'Position');
            
            margin = 5;
            buttonHeight = 25;
            
            if(~isempty(panelPosition))
                Figure.setObjectPositionInPixels(this.regionOfInterestTable, [margin, buttonHeight + margin, panelPosition(3) - margin*2, panelPosition(4) - margin*2 - buttonHeight - 20]);
                Figure.setObjectPositionInPixels(this.editRegionOfInterestButton, [panelPosition(3)*2/3, margin, panelPosition(3)*1/3 - margin, buttonHeight]);
                Figure.setObjectPositionInPixels(this.saveRegionOfInterestButton, [margin, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                Figure.setObjectPositionInPixels(this.loadRegionOfInterestButton, [margin+panelPosition(3)*1/5, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                Figure.setObjectPositionInPixels(this.infoRegionOfInterestButton, [margin+panelPosition(3)*2/5, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
            end
        end
    end
end