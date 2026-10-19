#
#  DYYY
#
#  Copyright (c) 2024 huami. All rights reserved.
#  Channel: @huamidev
#  Created on: 2024/10/04
#
# 本地配置文件（可选）
-include Makefile.local

TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

#export THEOS_PACKAGE_SCHEME=roothide

# 本地默认 rootless；SCHEME=rootful / SCHEME=roothide 可切换
SCHEME ?= rootless
ifeq ($(SCHEME),roothide)
    export THEOS_PACKAGE_SCHEME = roothide
    export FINALPACKAGE = 1
else ifeq ($(SCHEME),rootful)
    unexport THEOS_PACKAGE_SCHEME
else ifeq ($(SCHEME),rootless)
    export THEOS_PACKAGE_SCHEME = rootless
    export FINALPACKAGE = 1
else
    $(error Unknown SCHEME=$(SCHEME); use rootless, rootful, or roothide)
endif

# 在GitHub Actions中运行时的特殊配置
ifeq ($(GITHUB_ACTIONS),true)
    export INSTALL = 0
    export FINALPACKAGE = 1
endif

export DEBUG = 0
INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DYYY

DYYY_FILES = DYYY.xm \
	DYYYFloatClearButton.xm \
	DYYYSettings.xm \
	DYYYABTestHook.xm \
	DYYYLongPressPanel.xm \
	Sources/Features/DYYYFloatSpeedButton.m \
	Sources/Settings/DYYYSettingsHelper.m \
	Sources/Settings/DYYYPickerDelegates.m \
	Sources/Settings/DYYYSettingViewController.m \
	Sources/UI/DYYYKeyboardAvoidanceCoordinator.m \
	Sources/Features/DYYYLivePreStreamLayoutCoordinator.m \
	Sources/UI/DYYYBottomAlertView.m \
	Sources/UI/DYYYCustomInputView.m \
	Sources/UI/DYYYOptionsSelectionView.m \
	Sources/UI/DYYYIconOptionsDialogView.m \
	Sources/UI/DYYYAboutDialogView.m \
	Sources/UI/DYYYGlassConfirmView.m \
	Sources/UI/DYYYKeywordListView.m \
	Sources/UI/DYYYMediaChooserSheet.m \
	Sources/UI/DYYYFilterSettingsView.m \
	Sources/UI/DYYYConfirmCloseView.m \
	Sources/UI/DYYYToast.m \
	Sources/Media/DYYYManager.m \
	Sources/Core/DYYYUtils.m \
	Sources/Features/DYYYLoginBypassManager.m \
	Sources/Features/DYYYLoginRepairHooks.m \
	Sources/Features/DYYYPrivacyRecordUploadGuard.m \
	Sources/Core/CityManager.m \
	Sources/Core/AWMSafeDispatchTimer.m \
	Sources/Features/DYYYMiniProgramRewardBypass.m \
	Sources/Features/DYYYHideMusicButtonHooks.m \
	Sources/Features/DYYYHideShareContentViewHooks.m \
	Sources/Features/DYYYHideMessageAndMinePageHooks.m \
	Sources/Features/DYYYHideCommentAIAnalysisHooks.m \
	Sources/Features/DYYYHideTemplateCollectionHooks.m \
	Sources/Features/DYYYSearchKeyboardVoiceHooks.m \
	Sources/Features/DYYYHighFPSHooks.m \
	Sources/Features/DYYYFPSOverlay.m \
	Sources/Features/DYYYFeedTagHooks.m \
	Sources/Features/DYYYExactInteractionCountHooks.m \
	Sources/Hooking/DYYYRuntimeHookInstaller.m \
	Sources/Hooking/DYYYHookManager.m
DYYY_CFLAGS = -fobjc-arc -w \
	-I$(THEOS_PROJECT_DIR)/Sources/Core \
	-I$(THEOS_PROJECT_DIR)/Sources/Settings \
	-I$(THEOS_PROJECT_DIR)/Sources/UI \
	-I$(THEOS_PROJECT_DIR)/Sources/Media \
	-I$(THEOS_PROJECT_DIR)/Sources/Features \
	-I$(THEOS_PROJECT_DIR)/Sources/Hooking
DYYY_LDFLAGS = -weak_framework AVFAudio -lcompression
DYYY_FRAMEWORKS = UIKit Foundation AVFoundation CoreAudio UniformTypeIdentifiers
CXXFLAGS += -std=c++11
CCFLAGS += -std=c++11
DYYY_LOGOS_DEFAULT_GENERATOR = internal

export THEOS_STRICT_LOGOS=0
export ERROR_ON_WARNINGS=0
export LOGOS_DEFAULT_GENERATOR=internal

include $(THEOS_MAKE_PATH)/tweak.mk

# 清理 packages 目录
clean::
	@echo -e "\033[31m==>\033[0m Cleaning packages…"
	@rm -rf .theos packages

after-package::
	@echo -e "\033[32m==>\033[0m Packaging complete."
