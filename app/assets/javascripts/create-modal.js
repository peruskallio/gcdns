(function($) {

$.fn.createModal = function(opts) {
    var id = "modal-" + new Date().getTime();
    var $el = $('<div class="modal fade" id="' + id + '" tabindex="-1" role="dialog" aria-labelledby="' + id + '-label"></div>');
    var $dialog = $('<div class="modal-dialog" role="document"></div>');
    var $content = $('<div class="modal-content"></div>');
    var $header = $('<div class="modal-header"></div>');
    var $close = $('<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>');
    var $title = $('<h4 class="modal-title" id="' + id + '-label">' + opts.title + '</h4>');
    var $body = $('<div class="modal-body"></div>');
    var $footer = $('<div class="modal-footer"></div>');

    $el.append($dialog);
    $dialog.append($content);
    $content.append($header);
    $header.append($close);
    $header.append($title);
    $content.append($body);
    $content.append($footer);

    if (opts.type == "alert") {
        $body.append($('<div class="alert alert-danger">' + opts.message + '</div>'));
        var button = opts.button ? opts.button : 'OK';
        $footer.append($('<button type="button" class="btn btn-default" data-dismiss="modal">' + button + '</button>'));
    } else {
        $.error('Unknown modal type ' + opts.type);
    }

    $el.on('hidden.bs.modal', function (e) {
        $el.remove();
    });

    $el.modal('show');
    return $el;
};


}(jQuery));
