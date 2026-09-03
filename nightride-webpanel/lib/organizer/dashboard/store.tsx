"use client";

import { createContext, useContext, useMemo, useSyncExternalStore, type Context, type ReactNode } from "react";
import { clockStore } from "./browser-stores";
import { useOrganizerAuth } from "./auth";
import { DAYS } from "./constants";
import { useVenues, type VenuesState } from "./hooks/useVenues";
import { useEvents, type EventsState } from "./hooks/useEvents";
import { useReviews, type ReviewsState } from "./hooks/useReviews";
import { useInbox, type InboxState } from "./hooks/useInbox";
import { useTeam, type TeamState } from "./hooks/useTeam";
import { usePromotion, type PromotionState } from "./hooks/usePromotion";
import { usePerformance, type PerformanceState } from "./hooks/usePerformance";
import { useAiVisibility, type AiVisibilityState } from "./hooks/useAiVisibility";
import { useActivity, type ActivityState } from "./hooks/useActivity";
import { useAccountSettings, type AccountSettingsState } from "./hooks/useAccountSettings";
import { useDashboardUi, type DashboardUiState } from "./hooks/useDashboardUi";

export type { VenueTab } from "./hooks/useVenues";
export type { EventFilter, EventsTab } from "./hooks/useEvents";
export type { AccountTab, AudienceTab, HomeTab } from "./hooks/useDashboardUi";
export type { ChangeField, ChangeStage } from "./hooks/useAccountSettings";
export { blankVenueProfile } from "./hooks/useVenues";
export { blankEventDraft } from "./hooks/useEvents";
export { heroSlotId, gallerySlotId, gallerySlotIds, menuItemSlotId, eventSlotIds } from "./data/images";

// ---------------------------------------------------------------------------
// Eight contexts, one per domain-hook group. Each is published independently
// so a future consumer can subscribe to just the slice it needs; the facade
// below (`useOrganizerDashboard`) merges them for the 34 existing call sites,
// none of which need to change.
// ---------------------------------------------------------------------------

const IdentityContext = createContext<AccountSettingsState | null>(null);
const VenuesContext = createContext<VenuesState | null>(null);
const EventsContext = createContext<EventsState | null>(null);
const EngagementContext = createContext<{ reviews: ReviewsState; inbox: InboxState } | null>(null);
const AccountContext = createContext<{ team: TeamState; promotion: PromotionState } | null>(null);
const AnalyticsContext = createContext<{ performance: PerformanceState; aiVisibility: AiVisibilityState } | null>(null);
const ActivityContext = createContext<ActivityState | null>(null);
const UiContext = createContext<DashboardUiState | null>(null);

export function OrganizerDashboardProvider({ children }: { children: ReactNode }) {
  const { uid } = useOrganizerAuth();
  const ui = useDashboardUi();
  const identity = useAccountSettings();
  // `uid` is guaranteed non-null here: `OrganizerDashboardProvider` only ever
  // mounts inside `OrganizerGate` once auth status is "approved".
  const venues = useVenues(uid as string, ui.showSnack);
  const events = useEvents(uid as string, venues.data.profiles, venues.data.order, venues.data.meta, ui.showSnack);
  const reviews = useReviews(ui.showSnack);
  const inbox = useInbox();
  const team = useTeam(ui.showSnack);
  const promotion = usePromotion(ui.showSnack);
  const now = useNow();
  const performance = usePerformance(events.data.events, now);
  const aiVisibility = useAiVisibility();
  const activity = useActivity();

  const engagementValue = useMemo(() => ({ reviews, inbox }), [reviews, inbox]);
  const accountValue = useMemo(() => ({ team, promotion }), [team, promotion]);
  const analyticsValue = useMemo(() => ({ performance, aiVisibility }), [performance, aiVisibility]);

  return (
    <IdentityContext.Provider value={identity}>
      <VenuesContext.Provider value={venues}>
        <EventsContext.Provider value={events}>
          <EngagementContext.Provider value={engagementValue}>
            <AccountContext.Provider value={accountValue}>
              <AnalyticsContext.Provider value={analyticsValue}>
                <ActivityContext.Provider value={activity}>
                  <UiContext.Provider value={ui}>{children}</UiContext.Provider>
                </ActivityContext.Provider>
              </AnalyticsContext.Provider>
            </AccountContext.Provider>
          </EngagementContext.Provider>
        </EventsContext.Provider>
      </VenuesContext.Provider>
    </IdentityContext.Provider>
  );
}

function useCtx<T>(ctx: Context<T | null>, name: string): T {
  const value = useContext(ctx);
  if (!value) throw new Error(`${name} must be used inside <OrganizerDashboardProvider>`);
  return value;
}

/**
 * The pre-refactor `OrganizerDashboardValue` shape, unchanged in every key
 * name save the three deliberate corrections noted in the task brief
 * (`organizer`'s type, `activity`'s type, `blankEventDraft`'s signature) and
 * the deletion of `approveVenue` (a mock backdoor `firestore.rules` doesn't
 * allow for real: `verified` is admin-only on every organizer write).
 *
 * Merges the 8 contexts above into one facade so the 34 existing call sites
 * across 20 files keep compiling untouched. The dependency array is 8
 * entries — one per context value, each already its own hook's
 * pre-memoised object — where the hand-maintained version this replaces ran
 * to ~55.
 */
export function useOrganizerDashboard() {
  const identity = useCtx(IdentityContext, "useOrganizerDashboard");
  const venues = useCtx(VenuesContext, "useOrganizerDashboard");
  const events = useCtx(EventsContext, "useOrganizerDashboard");
  const engagement = useCtx(EngagementContext, "useOrganizerDashboard");
  const account = useCtx(AccountContext, "useOrganizerDashboard");
  const analytics = useCtx(AnalyticsContext, "useOrganizerDashboard");
  const activity = useCtx(ActivityContext, "useOrganizerDashboard");
  const ui = useCtx(UiContext, "useOrganizerDashboard");

  return useMemo(() => {
    const v = venues.data;
    const e = events.data;
    const r = engagement.reviews.data;
    const ib = engagement.inbox.data;
    const t = account.team.data;
    const pr = account.promotion.data;
    const perf = analytics.performance.data;
    const idn = identity.data;
    const u = ui.data;

    return {
      organizer: idn.organizer,

      // ---- Venues ----
      // `v.order`/`v.profiles` are the hook's internal names (fix round:
      // renamed from `venueOrder`/`venues` so the hook's own `data` shape is
      // `{ order, profiles, meta }` per the brief); re-mapped back to the
      // `venueOrder`/`venues` keys every existing call site already uses, so
      // no consumer outside this file needs to change.
      venueOrder: v.order,
      venues: v.profiles,
      venueMeta: v.meta,
      venuesLoading: v.venuesLoading,
      venuesError: v.venuesError,
      editingVenue: v.editingVenue,
      profile: v.profile,
      savedProfile: v.savedProfile,
      venueDirty: v.venueDirty,
      venueBusy: venues.busy,
      venueActionError: venues.actionError,
      liveBusy: v.liveBusy,
      menuLoading: v.menuLoading,
      saveVenue: venues.saveVenue,
      discardVenue: venues.discardVenue,
      venueTab: v.venueTab,
      addingVenue: v.addingVenue,
      newVenueName: v.newVenueName,
      newVenueCity: v.newVenueCity,
      newVenueCountry: v.newVenueCountry,
      approximateLocationVenues: v.approximateLocationVenues,
      setEditingVenue: venues.setEditingVenue,
      setVenueTab: venues.setVenueTab,
      openAddVenue: venues.openAddVenue,
      cancelAddVenue: venues.cancelAddVenue,
      setNewVenueName: venues.setNewVenueName,
      setNewVenueCity: venues.setNewVenueCity,
      setNewVenueCountry: venues.setNewVenueCountry,
      createVenue: () => venues.createVenue(DAYS),
      setVenueField: venues.setVenueField,
      toggleVenueSetValue: venues.toggleVenueSetValue,
      addSocialLink: venues.addSocialLink,
      removeSocialLink: venues.removeSocialLink,
      setSocialLinkField: venues.setSocialLinkField,
      setHourField: venues.setHourField,
      toggleDayClosed: venues.toggleDayClosed,
      addException: venues.addException,
      removeException: venues.removeException,
      setExceptionField: venues.setExceptionField,
      toggleExceptionClosed: venues.toggleExceptionClosed,
      addMenuSection: venues.addMenuSection,
      removeMenuSection: venues.removeMenuSection,
      setMenuSectionName: venues.setMenuSectionName,
      addMenuItem: venues.addMenuItem,
      removeMenuItem: venues.removeMenuItem,
      setMenuItemField: venues.setMenuItemField,
      toggleMenuItemSoldOut: venues.toggleMenuItemSoldOut,
      toggleMenuItemTag: venues.toggleMenuItemTag,
      toggleMenuItemNight: venues.toggleMenuItemNight,
      toggleVerifyStep: venues.toggleVerifyStep,

      // ---- Destination tab strips ----
      homeTab: u.homeTab,
      setHomeTab: ui.setHomeTab,
      eventsTab: e.eventsTab,
      setEventsTab: events.setEventsTab,
      audienceTab: u.audienceTab,
      setAudienceTab: ui.setAudienceTab,
      accountTab: u.accountTab,
      setAccountTab: ui.setAccountTab,

      // ---- Events ----
      events: e.events,
      eventsLoading: e.eventsLoading,
      eventsError: e.eventsError,
      eventBusy: events.busy,
      eventActionError: events.actionError,
      eventFilter: e.eventFilter,
      setEventFilter: events.setEventFilter,
      eventEditorOpen: e.eventEditorOpen,
      editingEventId: e.editingEventId,
      eventDraft: e.eventDraft,
      lineupInput: e.lineupInput,
      cancelingEventId: e.cancelingEventId,
      cancelReasonInput: e.cancelReasonInput,
      openNewEvent: events.openNewEvent,
      openEditEvent: events.openEditEvent,
      closeEditor: events.closeEditor,
      updateDraft: events.updateDraft,
      setLineupInput: events.setLineupInput,
      addLineup: events.addLineup,
      removeLineup: events.removeLineup,
      addTier: events.addTier,
      updateTier: events.updateTier,
      removeTier: events.removeTier,
      saveDraftEvent: events.saveDraftEvent,
      submitEvent: events.submitEvent,
      duplicateEvent: events.duplicateEvent,
      startCancel: events.startCancel,
      cancelCancelFlow: events.cancelCancelFlow,
      setCancelReasonInput: events.setCancelReasonInput,
      confirmCancel: events.confirmCancel,

      // ---- Calendar ----
      calendarOffset: e.calendarOffset,
      calendarVenueFilter: e.calendarVenueFilter,
      dayDialog: e.dayDialog,
      openDayDialog: events.openDayDialog,
      closeDayDialog: events.closeDayDialog,
      shiftCalendar: events.shiftCalendar,
      setCalendarVenueFilter: events.setCalendarVenueFilter,

      // ---- Tonight ----
      tonight: v.tonight,
      setDoorStatus: venues.setDoorStatus,
      setQueueMinutes: venues.setQueueMinutes,
      setFlashText: venues.setFlashText,
      setFlashUntil: venues.setFlashUntil,
      toggleFlash: venues.toggleFlash,
      toggleEmergency: venues.toggleEmergency,
      flushQueueMinutesNow: venues.flushQueueMinutesNow,
      flushFlashNow: venues.flushFlashNow,
      flushMenuWrite: venues.flushMenuWrite,

      // ---- Performance ----
      perfVenueFilter: perf.perfVenueFilter,
      perfEventId: perf.perfEventId,
      setPerfVenueFilter: analytics.performance.setPerfVenueFilter,
      setPerfEventId: analytics.performance.setPerfEventId,

      // ---- Promotion ----
      push: pr.push,
      setPushMessage: account.promotion.setPushMessage,
      sendPush: account.promotion.sendPush,
      promos: pr.promos,
      addPromo: account.promotion.addPromo,
      updatePromo: account.promotion.updatePromo,
      removePromo: account.promotion.removePromo,
      perks: pr.perks,
      updatePerk: account.promotion.updatePerk,
      boost: pr.boost,
      setBoostNight: account.promotion.setBoostNight,
      toggleBoost: account.promotion.toggleBoost,

      // ---- Team ----
      team: t.team,
      activity: activity.data.activity,
      inviteEmail: t.inviteEmail,
      setInviteEmail: account.team.setInviteEmail,
      sendInvite: account.team.sendInvite,
      setTeamRole: account.team.setTeamRole,
      removeTarget: t.removeTarget,
      removePassword: t.removePassword,
      removeAck: t.removeAck,
      removeError: t.removeError,
      startRemoveTeamMember: account.team.startRemoveTeamMember,
      setRemovePassword: account.team.setRemovePassword,
      toggleRemoveAck: account.team.toggleRemoveAck,
      cancelRemoveTeamMember: account.team.cancelRemoveTeamMember,
      confirmRemoveTeamMember: account.team.confirmRemoveTeamMember,

      // ---- Snackbar ----
      snack: u.snack,
      showSnack: ui.showSnack,
      dismissSnack: ui.dismissSnack,

      // ---- Reviews & inbox ----
      reviews: r.reviews,
      setReviewReply: engagement.reviews.setReviewReply,
      toggleReviewFlag: engagement.reviews.toggleReviewFlag,
      sendReviewReply: engagement.reviews.sendReviewReply,
      editPostedReply: engagement.reviews.editPostedReply,
      deletePostedReply: engagement.reviews.deletePostedReply,
      inbox: ib.inbox,
      toggleInboxItem: engagement.inbox.toggleInboxItem,
      hasUnreadInbox: ib.hasUnreadInbox,

      // ---- Settings / account ----
      accountEmail: idn.accountEmail,
      accountPhone: idn.accountPhone,
      changeField: idn.changeField,
      changeStage: idn.changeStage,
      changeValue: idn.changeValue,
      changeOtp: idn.changeOtp,
      changeError: idn.changeError,
      startChangeField: identity.startChangeField,
      cancelChangeField: identity.cancelChangeField,
      setChangeValue: identity.setChangeValue,
      setChangeOtp: identity.setChangeOtp,
      submitNewValue: identity.submitNewValue,
      submitOtp: identity.submitOtp,

      // ---- Image slots ----
      images: u.images,
      setImage: ui.setImage,
      confirmRemoveSlotId: u.confirmRemoveSlotId,
      requestRemoveImage: ui.requestRemoveImage,
      cancelRemoveImage: ui.cancelRemoveImage,
      confirmRemoveImage: ui.confirmRemoveImage,
    };
  }, [identity, venues, events, engagement, account, analytics, activity, ui]);
}

/**
 * The client's clock, or null until mounted.
 *
 * Anything time-dependent (is this event live *right now*, which month is it,
 * are we open today) must not render differently on the server than on the
 * client, so callers render a stable fallback while this is null.
 */
export function useNow(): Date | null {
  return useSyncExternalStore(clockStore.subscribe, clockStore.getSnapshot, clockStore.getServerSnapshot);
}
