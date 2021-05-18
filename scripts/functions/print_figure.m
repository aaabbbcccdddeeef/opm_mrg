
function print_figure(subject, figure_handle, figure_fname)
    % save figure and deal with problems arising from the remote desktop
    % setup
    set(figure_handle, 'color', [1 1 1])
    
    set(figure_handle, 'PaperUnits', 'centimeters', 'Units', 'centimeters');
    fig_pos = get(figure_handle, 'Position');
    set(figure_handle, 'PaperSize', fig_pos(3:4), 'Units', 'centimeters');
    
    set(figure_handle,'Visible', 'off');
    
    drawnow
    % use this for shaded figures:
    % print(figure_handle, '-depsc', '-painters', figure_fname)
    print(figure_handle, '-dpdf', '-bestfit', figure_fname)
    
    close all    
    
    fprintf('Saved figure for participant %s. \n', subject)
    