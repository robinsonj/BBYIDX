jQuery(document).ready(function($) {
  $(document).ready(function()
  {
    var ideaX = new Object;
    
    // form text hints - currently using example_text.js instead of jquery.
    //$('input[title], textarea[title]').hint();
    
    // share tab
    ideaX.shareTabText = $('#share .footer .tab').text();
    $('#share .footer .tab').unbind('click').click(function() {
      $('#share .body').slideToggle('normal', function() {
        if ($('#share .body:visible').length) {
          $('#share .footer .tab span').fadeOut('fast', function() {
            $('#share .footer .tab span').text('Close this').removeClass('dn').addClass('up');
            $(this).fadeIn();
          });
        }
        else {
          $('#share .footer .tab span').fadeOut('fast', function() {
            $('#share .footer .tab span').text(ideaX.shareTabText).removeClass('up').addClass('dn');
            $(this).fadeIn();
          });
        }
      });
      return false;
    });
  });
});
