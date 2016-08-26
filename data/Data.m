classdef Data < handle
    % Data Abstract base class for data.
    
    properties (SetAccess = private)
        % Description of the data stored within class.
        description = 'Data';
    end
    
    events
        % Triggered when the data is changed.
        DataChanged;
    end
    
    methods
        function setDescription(this, description)
            % setDescription Set the description of the data.
            %
            %   setDescription(description)
            %       description - Description of the data
            this.description = description;
        end
        
        function description = getDescription(this)
            % getDescription Get the description of the data.
            %
            %   description = getDescription()
            %       description - Description of the data
            
            description = this.description;
        end
        
        function exportToWorkspace(this)
            % exportToWorkspace Export this object to the MATLAB workspace.
            %
            %   exportToWorkspace()
            
            % Default variable name
            variableName = {'data'};
            
            % Check that the variable name is a valid one, otherwise
            % request again
            while(~isempty(variableName))
                % Request a variable name to export to
                variableName = inputdlg('Invalid variable name. Please specifiy a variable name:', 'Variable name', 1, variableName);
                
                if(isvarname(variableName{1}))
                    % Export variable to workspace
                    assignin('base', variableName{1}, this);
                    
                    break;
                end
            end
        end
        
    end
    
    methods (Abstract)
        % exportToImage Export this object to an image file.
        %
        %   exportToImage()
        exportToImage(obj);
        
        % exportToLaTeX Export this object to a LaTeX compatible file.
        %
        %   exportToLaTeX()
        exportToLaTeX(obj);
    end
end