import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart' hide AFRolePB;
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sidebar shortcut that opens the workspace calendar.
///
/// Reuses an existing calendar page when one is already in the workspace.
/// Otherwise it creates a calendar page named Meetings and opens that.
class SidebarMeetingsButton extends StatelessWidget {
  const SidebarMeetingsButton({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  static const _pageName = 'Meetings';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: HomeSizes.newPageSectionHeight,
      child: FlowyButton(
        onTap: () => _openMeetings(context),
        leftIcon: const FlowySvg(FlowySvgs.icon_calendar_s),
        leftIconSize: const Size.square(24),
        margin: const EdgeInsets.only(left: 4.0),
        iconPadding: 8.0,
        text: const FlowyText.regular(
          _pageName,
          lineHeight: 1.15,
        ),
      ),
    );
  }

  Future<void> _openMeetings(BuildContext context) async {
    final existing = await _findCalendar();
    if (!context.mounted) {
      return;
    }
    if (existing != null) {
      context.read<TabsBloc>().openPlugin(existing);
      return;
    }

    final workspaceState = context.read<UserWorkspaceBloc>().state;
    if (workspaceState.currentWorkspace?.role == AFRolePB.Guest) {
      return;
    }

    final spaceState = context.read<SpaceBloc>().state;
    if (spaceState.spaces.isNotEmpty) {
      context.read<SpaceBloc>().add(
            const SpaceEvent.createPage(
              name: _pageName,
              index: 0,
              layout: ViewLayoutPB.Calendar,
              openAfterCreate: true,
            ),
          );
      return;
    }

    final workspaceId = workspaceState.currentWorkspace?.workspaceId;
    if (workspaceId == null) {
      return;
    }

    final section = workspaceState.isCollabWorkspaceOn
        ? ViewSectionPB.Private
        : ViewSectionPB.Public;
    final result = await WorkspaceService(
      workspaceId: workspaceId,
      userId: userProfile.id,
    ).createView(
      name: _pageName,
      viewSection: section,
      layout: ViewLayoutPB.Calendar,
      setAsCurrent: true,
    );

    result.fold(
      (view) {
        if (context.mounted) {
          context.read<TabsBloc>().openPlugin(view);
        }
      },
      (error) => Log.error('Failed to open Meetings: $error'),
    );
  }

  Future<ViewPB?> _findCalendar() async {
    final views = (await ViewBackendService.getAllViews()).toNullable()?.items;
    if (views == null || views.isEmpty) {
      return null;
    }

    for (final view in views) {
      if (view.layout == ViewLayoutPB.Calendar && view.name == _pageName) {
        return view;
      }
    }
    for (final view in views) {
      if (view.layout == ViewLayoutPB.Calendar) {
        return view;
      }
    }
    return null;
  }
}
