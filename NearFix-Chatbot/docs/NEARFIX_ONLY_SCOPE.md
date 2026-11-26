# NearFix-only customer chatbot scope

## Objective
Build a standalone, rule-based **NearFix customer chatbot**, using Flutter/Dart in the existing `my_first_app` project. Languages are **English and Tamil (தமிழ்)** only. Do not add Tanglish or any other language.

## Authoritative feature scope
Use the original `Project_Summary_Nearby_Service_App.txt` for the NearFix nearby commercial-service concept. The chatbot should explain the proposed platform: service categories, customer service requests, problems, area/location input, planned discovery of providers, proposed provider profiles, quotations, request statuses, contact and reviews. Keep prototype capabilities and future concepts distinct.

## Current prototype
Customer chat screen, rule-based classification, conversation state, bilingual FAQ matching, and fictional demo provider recommendations are implemented in the standalone prototype and verified with unit and widget tests. Use fictional provider records only and visibly label them as demos. No live GPS provider search, booking, payment, account management, real availability, emergency dispatch, or provider contact is assumed.

## Knowledge exclusions
This chatbot must not be a chatbot for other projects, disaster relief, NGOs, donors, volunteers, or SOS coordination. Do **not** import content or commission figures from any combined-app/other-project financial proposal and state it as a confirmed NearFix policy. NearFix-specific fees and refund policies are not finalized in the original nearby-service proposal. If asked, explain that they are not confirmed yet, rather than inventing terms.

## Language/FAQ matching
Automatically detect **English** and **Tamil (தமிழ்)** from each customer message without manual language selector buttons, preserve the established conversation language on short neutral follow-ups (such as town names), and switch naturally when the customer changes language. Do not add Tanglish support; return a polite English/Tamil clarification when unsupported mixed-language or Tanglish text cannot be reliably interpreted. A rule-based bot does not understand all paraphrases automatically: support keyword patterns and reasonable synonyms, prefer checking common FAQ intents before treating any word as a new service request, ask clarifying questions for ambiguous terms such as `battery` (vehicle vs phone) or tied FAQ matches, and return a polite NearFix-specific fallback for unknown questions.

## Safety and privacy
Do not fabricate real providers, ratings, prices, booking confirmations, arrival times, successful payments or contact details. Do not store or expose sensitive customer data unnecessarily. For immediate danger provide basic safety guidance and tell users to contact official emergency services directly; never imply this chatbot dispatches help.

