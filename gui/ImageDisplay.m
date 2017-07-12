classdef ImageDisplay < Display
    properties (SetAccess = private)
        imageHandle;
        
        regionOfInterestList;
    end
    
    properties (Access = protected)
        colourMap = 'pink';
        axisVisibility = 'off';
        colourBarOn = 1;
    end
    
    events
        PixelSelected
    end
    
    methods
        function obj = ImageDisplay(axisHandle, image)
            obj = obj@Display(axisHandle, image);
            
            if(~isa(image, 'Image'))
                exception = MException('ImageDisplay:invalidArgument', 'Must provide an instance of a class that extends Image');
                throw(exception);
            end
            
            obj.regionOfInterestList = RegionOfInterestList();
            
            obj.updateDisplay();
            
            addlistener(image, 'DataChanged', @(src, evnt)obj.updateDisplay());
        end
        
        % Open the data in a new window. Any changes made the the
        % underlying image will be updated in the new display too
        function display = openInNewWindow(obj)
            figure = Figure;
            figure.showStandardFigure();
%             axisHandle = axes;
            display = ImageDisplay(figure, obj.data);
            
            display.copy(obj);
        end
        
        % Open a copy of the data in a new window so that if any changes
        % are made to the image in this display they aren't updated in
        % the new display
        function display = openCopyInNewWindow(obj)
            figure = Figure;
            figure.showStandardFigure();
%             axisHandle = axes;
            display = ImageDisplay(figure, Image(obj.data.imageData));
            
            display.copy(obj);
        end
        
        function exportToImage(obj)
            [fileName, pathName, filterIndex] = uiputfile([obj.lastSavedPath 'image.pdf'], 'Export image');
            
            if(filterIndex > 0)
                obj.lastSavedPath = [pathName filesep];
                
                f = figure;%('Visible', 'off');
                pos = get(f, 'Position');
                set(f, 'Position', pos*2);
                
                axisHandle = axes;
                colorbar(axisHandle);
                normPos = get(axisHandle, 'Position');
                delete(axisHandle);

%                 axisHandle = axes;
%                 display = ImageDisplay(axisHandle, obj.data);
% 
%                 display.copy(obj);
%                 
%                 set(f, 'Color', 'none');
%                 
%                 export_fig(f, [pathName filesep fileName], '-painters', '-transparent');

                newAxis = copyobj(obj.axisHandle, f);
                colormap(f, obj.colourMap);
                
                
                cb = colorbar(newAxis, 'southoutside');
                
                set(cb, 'Units', get(f, 'PaperUnits'));
                cbSouthPos = get(cb, 'Position');
                set(cb, 'Units', 'normalized');
                
                delete(cb);
                
                cb = colorbar(newAxis);
                
                set(cb, 'Units', get(f, 'PaperUnits'));
                cbPos = get(cb, 'Position');
                set(cb, 'Units', 'normalized');
                    
                if(~obj.colourBarOn)
                    delete(cb);
                end
                
                
                set(newAxis, 'Position', normPos);                
                
%                 set(newAxis, 'Units', get(f, 'PaperUnits'));
%                 axisPos = get(newAxis, 'Position');
%                 set(newAxis, 'Units', 'normalized');
                
                
                
%                 get(cb, 'Position')
%                 get(newAxis, 'Position')
                
                
                % Use the colour bar as a better indicator of the height
                imageWidth = cbSouthPos(3) + 3;
                imageHeight = cbPos(4) + 1;
                
                set(f, 'PaperSize', [imageWidth imageHeight]);
                set(f, 'PaperPosition', [-0.5 -0.25 imageWidth imageHeight]);
                set(f, 'PaperPositionMode', 'manual');
                set(f, 'Color', 'None');
                
                print(f, [pathName filesep fileName], '-dpdf', '-painters', '-r600');

%                 delete(f);
            end
        end
        
        function exportToLaTeX(obj)
        end
        
        function setColourMap(obj, colourMap)
            obj.colourMap = colourMap;
            
            obj.updateDisplay();
        end
        
        function setColourBarOn(obj, colourBarOn)
            obj.colourBarOn = colourBarOn;
            
            if(obj.colourBarOn)
                colorbar;
            else
                colorbar('off');
            end
            
            obj.updateDisplay();
        end
                
        function addRegionOfInterest(this, regionOfInterest)
            this.regionOfInterestList.add(regionOfInterest);
        end
        
        function removeAllRegionsOfInterest(this)
            this.regionOfInterestList.removeAll();
            
            this.updateDisplay();
        end
            
        
        function updateDisplay(obj)            
            axes(obj.axisHandle);
            
            if(isempty(obj.imageHandle))
                obj.imageHandle = imagesc(obj.data.imageData);
            else
%                 set(obj.imageHandle, 'CData', obj.data.imageData);
                obj.imageHandle = imagesc(obj.data.imageData);
            end
            
            set(obj.imageHandle, 'AlphaData', 1);
            
            axis image;
            
            colormap(obj.axisHandle, obj.colourMap);
            set(obj.axisHandle, 'Visible', obj.axisVisibility);
            
            if(isa(obj.regionOfInterestList, 'RegionOfInterestList'))
                roisToDisplay = obj.regionOfInterestList.getObjects();

                if(~isempty(roisToDisplay))
                    % Display the image in grayscale if we're showing ROIs for
                    % ease of visbility
                    colormap gray;

                    hold(obj.axisHandle, 'on');
                    
                    maxDisplayedVal = max(obj.data.imageData(:));
                    
                    roiImage = zeros(size(obj.data.imageData, 1), size(obj.data.imageData, 2), 3);
                    alphaChannel = zeros(size(obj.data.imageData));
                    
                    for i = 1:numel(roisToDisplay)
                        roiImage = roiImage + double(roisToDisplay{i}.getImage());

                        alphaChannel = alphaChannel + (sum(roiImage, 3) ~= 0);
    %                     roiImage = (roiImage ./ 255);
    %                     max(roiImage(:))
    %                     maxDisplayedVal
    %                     obj.imageHandle = imagesc(roiImage);
    %                     set(obj.imageHandle, 'AlphaData', 0.5 / numel(roisToDisplay));
                    end
                    
                    obj.imageHandle = imagesc(roiImage./max(roiImage(:)));
                    set(obj.imageHandle, 'AlphaData', 0.5);
                    
                    hold(obj.axisHandle, 'off');
                end
            end
                
            set(obj.imageHandle, 'ButtonDownFcn', @(src, evnt)obj.buttonDownCallback());
            
            % Reset necessary callbacks
            set(obj.axisHandle, 'UIContextMenu', obj.contextMenu);
            set(obj.imageHandle, 'UIContextMenu', obj.contextMenu);
            
            % Ensure that notifications are made that the display has
            % changed
            updateDisplay@Display(obj);
        end
    end
    
    methods (Access = protected)
        function copy(obj, oldobj)
            obj.colourMap = oldobj.colourMap;
            obj.axisVisibility = oldobj.axisVisibility;
            obj.colourBarOn = oldobj.colourBarOn;
            
            obj.updateDisplay();
        end
        
        function buttonDownCallback(obj)
            currentPoint = get(obj.axisHandle, 'CurrentPoint');
            
            fig = gcbf;
            
            if(strcmp(get(fig, 'SelectionType'), 'normal'))
                xPoint = currentPoint(1, 1);
                yPoint = currentPoint(1, 2);

                pse = PixelSelectionEvent(xPoint, yPoint);

                notify(obj, 'PixelSelected', pse);
            end
        end
    end
end