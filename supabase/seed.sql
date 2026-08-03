-- Sample content matching the WGN App design spec.
-- Dates are relative to current_date so the seeded app always looks "live".

insert into sermons
  (title, short_title, series, speaker, kind, preached_on, duration_secs, size_bytes, audio_path, youtube_id, scripture, scripture_ref)
values
  ('Set Apart For Glory', 'Elevate 118', 'ELEVATE SERVICE 118', 'Apostle Chidiebere E. Amanoh', 'audio', current_date - 4, 3482, 85983232, '1.m4a', null,
   '“But ye are a chosen generation, a royal priesthood, an holy nation, a peculiar people.”', '1 PETER 2:9 · KJV'),
  ('The Table He Prepared Before Me', 'The Table', 'MIDWEEK FEAST', 'Apostle Chidiebere E. Amanoh', 'audio', current_date - 11, 2650, 63963136, '2.m4a', null,
   '“Thou preparest a table before me in the presence of mine enemies.”', 'PSALM 23:5 · KJV'),
  ('A Testimony Is A Weapon', 'Testimony', 'ELEVATE SERVICE 117', 'Apostle Chidiebere E. Amanoh', 'audio', current_date - 18, 3096, 77594624, '3.m4a', null,
   '“And they overcame him by the blood of the Lamb, and by the word of their testimony.”', 'REVELATION 12:11 · KJV'),
  ('The Weight of a Sent Word', 'Sent Word', 'ELEVATE SERVICE 116', 'Apostle Chidiebere E. Amanoh', 'audio', current_date - 25, 3740, 92274688, '4.m4a', null,
   '“So shall my word be that goeth forth out of my mouth: it shall not return unto me void.”', 'ISAIAH 55:11 · KJV'),
  ('Feasting In A Famine', 'Famine', 'ELEVATE SERVICE 115', 'Pastor Ifeoma Anozie', 'audio', current_date - 32, 2822, 69206016, '5.m4a', null,
   '“In the days of famine they shall be satisfied.”', 'PSALM 37:19 · KJV'),
  ('Diaspora & Dominion', 'Diaspora', 'SPECIAL SESSION', 'Apostle Chidiebere E. Amanoh', 'audio', current_date - 39, 3314, 82837504, '6.m4a', null,
   '“Enlarge the place of thy tent.”', 'ISAIAH 54:2 · KJV'),
  ('Elevate 118 — Full Service', '118 Full', 'ELEVATE SERVICE 118', 'WordFeast Gospel Network', 'video', current_date - 4, 6724, null, null, 'dQw4w9WgXcQ',
   '“Where there is no vision, the people perish.”', 'PROVERBS 29:18 · KJV'),
  ('Night of Testimonies — July', 'Testimony Night', 'SPECIAL SESSION', 'WordFeast Gospel Network', 'video', current_date - 14, 7653, null, null, 'dQw4w9WgXcQ',
   '“Come and hear, all ye that fear God.”', 'PSALM 66:16 · KJV'),
  ('The Believer''s Authority — Part 1', 'Authority I', 'SERIES · AUTHORITY', 'Apostle Chidiebere E. Amanoh', 'series', current_date - 21, 2388, 56623104, '9.m4a', null,
   '“Behold, I give unto you power to tread on serpents.”', 'LUKE 10:19 · KJV'),
  ('The Believer''s Authority — Part 2', 'Authority II', 'SERIES · AUTHORITY', 'Apostle Chidiebere E. Amanoh', 'series', current_date - 28, 2532, 61865984, '10.m4a', null,
   '“Whatsoever ye shall bind on earth shall be bound in heaven.”', 'MATTHEW 18:18 · KJV');

insert into devotionals (for_date, title, verse, verse_ref, tag, body, prayer) values
  (current_date, 'Where Vision Ends, People Scatter',
   '“Where there is no vision, the people perish: but he that keepeth the law, happy is he.”',
   'PROVERBS 29:18 · KJV', 'Vision',
   array[
     'Vision is not ambition dressed in scripture. Ambition asks what I can hold; vision asks what God is already holding and invites me to carry a corner of it.',
     'Notice what Solomon says happens without it — the people scatter. Not that they sin, not that they fail; they scatter. A house without vision does not usually collapse in scandal. It simply drifts apart, one quiet Sunday at a time.',
     'That is why the second half of the verse matters as much as the first. He that keepeth the law, happy is he. Vision shows you the country; discipline walks you there. One without the other leaves you either dreaming or merely busy.',
     'So before this week gets loud: write down the one thing God has shown you that you have not yet obeyed. Vision that stays in the head is only imagination.'
   ],
   'Father, give me eyes for what You are building, and the discipline to walk toward it today. Amen.'),
  (current_date - 1, 'Step Out Before You See Land',
   '“And the LORD said unto Moses, Wherefore criest thou unto me? Speak unto the children of Israel, that they go forward.”',
   'EXODUS 14:15 · KJV', 'Faith',
   array[
     'There is a moment in every believer''s life when prayer becomes procrastination — when God has already spoken and the only thing left is a step.',
     'Israel stood at the water''s edge with an army behind them and a sea in front. Heaven''s instruction was not "pray harder." It was "go forward."',
     'Faith is not the absence of fear; it is motion in spite of it. The sea did not open for spectators.',
     'What has God already told you that you keep asking Him about? Take the step today, and let the water worry about itself.'
   ],
   'Lord, where You have spoken, give me the courage to move. Amen.'),
  (current_date - 2, 'The Promptings You Keep Postponing',
   '“If ye be willing and obedient, ye shall eat the good of the land.”',
   'ISAIAH 1:19 · KJV', 'Obedience',
   array[
     'Obedience delayed has a way of dressing itself up as wisdom. We call it waiting on God when He is, in fact, waiting on us.',
     'Isaiah joins two words we like to separate: willing and obedient. Plenty of us are willing — moved in the service, stirred on the drive home — and never obedient.',
     'The good of the land is not promised to the impressed. It is promised to the moved.',
     'Name the prompting you have postponed the longest. That is today''s assignment.'
   ],
   'Father, make my willingness walk. Amen.'),
  (current_date - 3, 'Faithful In What Belongs To Another',
   '“And if ye have not been faithful in that which is another man''s, who shall give you that which is your own?”',
   'LUKE 16:12 · KJV', 'Stewardship',
   array[
     'Before God hands you yours, He watches how you carry another''s.',
     'Serve someone else''s vision the way you want yours served. The measure you use is the measure being prepared for you.',
     'Faithfulness in obscurity is the entrance exam of every public assignment.',
     'Whose work are you carrying right now? Carry it like it is yours — because the way you carry it decides when yours arrives.'
   ],
   'Lord, teach me to be faithful where I am planted. Amen.'),
  (current_date - 4, 'A Quiet Mouth, A Guarded Life',
   '“He that keepeth his mouth keepeth his life.”',
   'PROVERBS 13:3 · KJV', 'Wisdom',
   array[
     'Not every thought deserves an audience, and not every provocation deserves a reply.',
     'Solomon links the mouth to the life — not the reputation, the life. Words are not commentary on your world; they are construction material for it.',
     'Silence is not weakness. Sometimes it is the loudest act of faith in the room.',
     'Today, before you answer anything sharp, wait one breath. Guard the door, and you guard the house.'
   ],
   'Father, set a watch over my mouth today. Amen.');

insert into events (name, starts_at, location, blurb, cta_type, spots_note) values
  ('Elevate Service 119', (current_date + 2) + time '09:00', 'Main Auditorium',
   'Communion Sunday. Doors open 8:15 AM; children''s church runs in parallel.', 'register', 'Open seating'),
  ('Midweek Feast', (current_date + 5) + time '18:00', 'Online & in person',
   'Teaching night on the Believer''s Authority, part 3. Streamed for the diaspora.', 'remind', 'Streaming too'),
  ('Diaspora Weekend 2026', (current_date + 14) + time '17:00', 'Lekki Conference Hall',
   'Three sessions for members abroad and visiting families. Registration required.', 'register', '212 of 400 taken'),
  ('City Outreach & Medical Camp', (current_date + 29) + time '10:00', 'Community Grounds',
   'Free clinic, food distribution and evening crusade. Volunteers still needed.', 'volunteer', 'Volunteers needed');

insert into testimonies (display_name, initials, location_tag, category, body, amens_base, approved) values
  ('Emeka Obi', 'EO', 'LAGOS · MEMBER', 'PROVISION',
   '“Two years of waiting on that contract, and the letter came the same week we prayed at Midweek Feast.”', 184, true),
  ('Grace Achebe', 'GA', 'MANCHESTER · ONLINE', 'HEALING',
   '“I listened offline on the night bus to Enugu and the pain in my back left before we arrived.”', 341, true),
  ('Tunde Nwosu', 'TN', 'ABUJA · MEMBER', 'FAMILY',
   '“My brother had not spoken to me in six years. He called on the Sunday of the Authority series.”', 97, true),
  ('Blessing M.', 'BM', 'TORONTO · ONLINE', 'WORK',
   '“I gave my first fruit with almost nothing left. The job offer came eleven days later.”', 212, true);

insert into journal_articles (issue_no, title, dek, read_mins, published_at) values
  (14, 'What the diaspora taught us about presence',
   'Half our Sunday is now watching from another timezone. That changed how we plan a service.', 9, current_date - 13),
  (13, 'Notes on fasting without noise',
   'A short pastoral letter on keeping a fast quiet enough that only God has to notice.', 6, current_date - 44),
  (12, 'The economics of a generous house',
   'Where the offering went last quarter, line by line, and what we are believing for next.', 12, current_date - 75),
  (11, 'Raising sons, not spectators',
   'On discipleship that survives after the music stops.', 8, current_date - 106);

insert into updates (title, body, published_at) values
  ('Elevate Service 119 this Sunday',
   'Communion Sunday. Doors open 8:15 AM — come early, the parking lot fills by 8:45.', current_date - 2),
  ('Diaspora Weekend registration is open',
   'Three sessions, three weeks out. Members abroad get priority until Friday.', current_date - 4),
  ('40 days of prayer — day 12 point',
   'Pray for households in transition: new cities, new work, new names.', current_date - 6),
  ('Medical outreach volunteers needed',
   'Nurses, pharmacists and crowd stewards for the outreach camp.', current_date - 9),
  ('The Journal, Issue 14 is out',
   'On presence, distance and what the diaspora taught us this year.', current_date - 13);

insert into broadcast_platforms (kind, name, schedule_text, sort_order) values
  ('TV', 'Faith TV — Nationwide', 'Sunday 7:30 am (WAT)', 1),
  ('TV', 'TBN Africa', 'Friday 8:30 pm · Sunday repeat 3:00 pm', 2),
  ('FM', 'Inspiration 92.3 FM', 'Weekdays 5:30 am', 3),
  ('WEB', 'YouTube — WordFeast Gospel Network', 'Live every service', 4);

insert into app_config (key, value) values
  ('live', jsonb_build_object(
    'is_live', true,
    'youtube_id', 'jfKfPfyJRdk',
    'service_name', 'Elevate Service',
    'service_no', 119,
    'title', 'Set Apart For Glory',
    'speaker', 'Apostle Chidiebere E. Amanoh',
    'started_at', now() - interval '24 minutes',
    'watching', 1482
  )),
  ('giving', jsonb_build_object(
    'purposes', jsonb_build_array('Offering', 'Tithe', 'First Fruit', 'Partnership', 'Building', 'Outreach'),
    'presets', jsonb_build_array(5000, 10000, 25000, 50000),
    'currency', '₦',
    'bank', jsonb_build_object(
      'bank_name', 'Zenith Bank',
      'account_name', 'WordFeast Gospel Network',
      'account_number', '1012345678'
    ),
    'mobile_money', jsonb_build_object(
      'provider', 'OPay',
      'number', '0801 234 5678',
      'name', 'WordFeast Gospel Network'
    ),
    'note', 'Use your name + purpose as the transfer reference so we can send a receipt.'
  )),
  ('prayer', jsonb_build_object(
    'categories', jsonb_build_array('Healing', 'Family', 'Provision', 'Direction', 'Salvation', 'Thanksgiving'),
    'promise', 'Our intercessors pray over every request within 24 hours. Nothing you write is published.'
  )),
  ('about', jsonb_build_object(
    'church_name', 'WordFeast Gospel Network',
    'app_version_note', 'WGN MOBILE',
    'blurb', 'WordFeast Gospel Network is a church family in Lagos, Nigeria, gathering in person and across the diaspora.',
    -- Left blank deliberately: the About screen hides rows with no URL, so an
    -- unconfigured stack shows fewer rows instead of shipping dead links.
    -- Must be filled in before store submission (see RELEASE_CHECKLIST.md A5).
    'website_url', '',
    'contact_email', '',
    'privacy_policy_url', '',
    'terms_url', '',
    'delete_account_url', ''
  ));
