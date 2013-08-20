

jQuery(function($) {
  $('[data-remote=true]').on('ajax:before',   function() { $(this).addClass('loading') })
  $('[data-remote=true]').on('ajax:complete', function() { $(this).removeClass('loading') })
  $('[data-remote=true]').on('ajax:success', function(event, data, status, xhr) {
    var update = $(this).data('update')
    if(update) {
      // Using "id=" matcher instead of "#" because our ids are sometimes note unique! (Ouch. But true.)
      $('[id="' + update + '"]').html(data)
    }
  })
})
