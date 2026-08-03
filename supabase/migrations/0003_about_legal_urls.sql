-- Legal + contact URLs for the About screen.
--
-- App Review 5.1.1(i) requires the privacy policy to be reachable from inside
-- the app, not just from the store listing; Play additionally requires a
-- web-reachable account-deletion route. These live in app_config so the church
-- can set them without an app release.
--
-- They are intentionally left EMPTY here. The About screen hides any row whose
-- URL is blank, so an unconfigured deployment shows fewer rows rather than
-- shipping dead links — which App Review 2.1 treats as incomplete. Fill these
-- in before submitting:
--
--   update app_config
--      set value = value || jsonb_build_object(
--            'website_url',        'https://wordfeast.org',
--            'contact_email',      'hello@wordfeast.org',
--            'privacy_policy_url', 'https://wordfeast.org/privacy',
--            'terms_url',          'https://wordfeast.org/terms',
--            'delete_account_url', 'https://wordfeast.org/delete-account')
--    where key = 'about';

update app_config
   set value = jsonb_build_object(
         'blurb',
         'WordFeast Gospel Network is a church family in Lagos, Nigeria, '
         || 'gathering in person and across the diaspora.',
         'website_url', '',
         'contact_email', '',
         'privacy_policy_url', '',
         'terms_url', '',
         'delete_account_url', ''
       ) || value,
       updated_at = now()
 where key = 'about';
