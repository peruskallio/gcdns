(function($) {

var methods = {
    init: function() {
        var $el = $(this);
        var userID = $(this).data('user-id');

        $('.remove-permission', $el).on('click', function(ev) {
            ev.preventDefault();
            var $permission = $(this).closest('.permission');
            var id = $permission.attr('id').split('-')[2];
            $(this).closest('.permission').append('<input type="hidden" class="destroy-permission" name="permissions[' + id + '][destroy_permission]" />');
            $permission.hide();
            if ($('.permission:visible', $el).length == 0) {
                $('.no-zones', $el).show();
            }
        });

        $('.add-permission', $el).on('click', function(ev) {
            ev.preventDefault();
            var id = $('select.permission-select', $el).val();
            if (id != "") {
                var name = $($('select.permission-select option[value=' + id + ']', $el)).html();
                var $permission = $('#zone-'+ userID + '-' + id);
                if ($permission.length > 0) {
                    $('.destroy-permission', $permission).remove();
                    $permission.show();
                } else {
                    $permission = methods.permissionElement(userID, id, name);
                }
                $('tr:last', $el).before($permission);
                $('.no-zones', $el).hide();
            }
        });
    },

    /* Please note that if you edit this element, you should
     * also edit the one at views/projects/_form !! */
    permissionElement: function(userID, id, name) {
        var $el = $('<tr></tr>');
        $el.attr('id', 'zone-' + userID + '-' + id);
        $el.attr('class', 'permission');
        $el.append('<td>' + name + ' <input type="hidden" name="permissions[' + id + '][read]" value="on"></td>');
        $.each(['edit', 'destroy'], function() {
            var $cell = $('<td class="text-center"></td>');
            $cell.append('<input type="checkbox" name="permissions[' + id + ']' + this + '" />');
            $el.append($cell);
        });
        $el.append('<td><a class="remove-permission btn btn-xs btn-danger pull-right">&times;</a></td>');
        return $el;
    }
};

$.fn.permissionUI = function() {
    $(this).each(function() {
       methods.init.apply(this);
    });
};
}(jQuery));
