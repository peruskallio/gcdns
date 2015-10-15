(function($) {

var methods = {
    init: function() {
        var $el = $(this);
        $('#project_keydata', $el).on('change', function() {
            methods.updateMode.apply($el);
        });
    },

    updateMode: function(status) {
        var $el = $(this);
        var split = $('#project_keydata', $el).val().split('.');
        if (split.length > 0 && split[split.length-1] == "p12") {
            $el.removeClass('file-json');
            $('#project_issuer', $el).val($('#project_issuer', $el).data('val'));
            $('#project_keypass', $el).val($('#project_keypass', $el).data('val'));
        } else {
            $el.addClass('file-json');
            $('#project_issuer', $el).data('val', $('#project_issuer', $el).val());
            $('#project_keypass', $el).data('val', $('#project_keypass', $el).val());
            $('#project_issuer', $el).val('');
            $('#project_keypass', $el).val('notasecret');
        }
    }

};

$.fn.projectForm = function() {
    $(this).each(function() {
       methods.init.apply(this);
    });
};
}(jQuery));
