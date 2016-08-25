classdef Data < handle
    properties (SetAccess = private)
        description = 'Data';
%         data;
    end
    
    events
        DataChanged;
    end
    
    methods
        function exportToWorkspace(obj)
            variableName = inputdlg('Please specifiy a variable name:', 'Variable name', 1, {'data'});
            
            while(~isempty(variableName))
                if(isvarname(variableName{1}))
                    assignin('base', variableName{1}, obj);
                    break;
                else
                    variableName = inputdlg('Invalid variable name. Please specifiy a variable name:', 'Variable name', 1, variableName);
                end
            end
        end
        
        function setDescription(obj, description)
            obj.description = description;
        end
        
        function description = getDescription(obj)
            description = obj.description;
        end
    end
    
    methods (Abstract)   
        exportToImage(obj);
        exportToLaTeX(obj);
    end
end