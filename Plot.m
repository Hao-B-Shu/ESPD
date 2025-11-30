function Plot(varargin)

Para = inputParser;

addRequired(Para, 'list', @(x)isnumeric(x) && ~isempty(x));

addOptional(Para, 'list_name', []);
addOptional(Para, 'Save', '');
addOptional(Para, 'Y_Scale', 'linear');
addOptional(Para, 'Y_Label', '');
addOptional(Para, 'Title', '');
addOptional(Para, 'y_range', [0 1]);

parse(Para, varargin{:});

list = Para.Results.list;
list_name = Para.Results.list_name;
Save = Para.Results.Save;
Y_Scale = Para.Results.Y_Scale;
Y_Label = Para.Results.Y_Label;
Title = Para.Results.Title;
y_range=Para.Results.y_range;

if isempty(list_name)
    list_name = arrayfun(@(x) sprintf('Series %d', x), 1:size(list,1), 'UniformOutput', false);
end

set(groot, 'defaultLineLineWidth', 2);
set(groot, 'defaultAxesLineWidth', 1.1);
set(groot, 'defaultAxesFontSize', 12);
set(groot, 'defaultAxesTitleFontSizeMultiplier', 1.05);
set(groot, 'defaultAxesTitleFontWeight','bold');
set(groot, 'defaultAxesFontWeight', 'bold');
set(groot, 'defaultTextInterpreter', 'latex');

N = 0:size(list,2)-1;
figure; hold on;
h1 = gobjects(size(list,1),1);

for i = 1:size(list,1)
    h1(i) = plot(N, list(i,:), 'DisplayName', list_name(i));
end

hold off;
set(gca,'XScale','linear');
set(gca,'YScale',Y_Scale);
axis([0 size(list,2)-1 y_range(1) y_range(2)]);
xticks(N);

xlabel('Level');
ylabel(Y_Label);
title(Title);

legend(h1,'Location','best','Interpreter','latex');
grid on;

if ~isempty(Save)
    print(gcf, '-depsc', Save);
end

end