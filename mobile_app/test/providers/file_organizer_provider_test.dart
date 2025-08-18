import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';

void main() {
  group('FileOrganizerProvider', () {
    late FileOrganizerProvider provider;

    setUp(() {
      provider = FileOrganizerProvider();
    });

    test('initial state is correct', () {
      expect(provider.sourcePath, isEmpty);
      expect(provider.destinationPath, isEmpty);
      expect(provider.organizationStyle, OrganizationStyle.smartCategories);
      expect(provider.customIntent, isEmpty);
      expect(provider.operations, isEmpty);
      expect(provider.status, OperationStatus.idle);
      expect(provider.hasOperations, false);
      expect(provider.canExecute, false);
      expect(provider.isAnalyzing, false);
      expect(provider.isExecuting, false);
      expect(provider.isIdle, true);
    });

    test('setSourcePath updates path and clears operations', () {
      // Add a mock operation first
      provider.setSourcePath('/test/source');
      provider.setDestinationPath('/test/dest');
      
      // Change source path
      provider.setSourcePath('/new/source');
      
      expect(provider.sourcePath, '/new/source');
      expect(provider.operations, isEmpty);
    });

    test('setDestinationPath updates path and clears operations', () {
      provider.setSourcePath('/test/source');
      provider.setDestinationPath('/test/dest');
      
      // Change destination path
      provider.setDestinationPath('/new/dest');
      
      expect(provider.destinationPath, '/new/dest');
      expect(provider.operations, isEmpty);
    });

    test('setOrganizationStyle updates style and clears operations', () {
      provider.setOrganizationStyle(OrganizationStyle.byType);
      
      expect(provider.organizationStyle, OrganizationStyle.byType);
      expect(provider.operations, isEmpty);
    });

    test('setCustomIntent updates intent and clears operations', () {
      provider.setCustomIntent('Test intent');
      
      expect(provider.customIntent, 'Test intent');
      expect(provider.operations, isEmpty);
    });

    test('approveOperation updates operation approval status', () {
      // Create a mock operation
      final operation = FileOperation(
        id: 'test_op',
        type: FileOperationType.move,
        sourcePath: '/test/file.txt',
        destinationPath: '/test/dest/file.txt',
        confidence: 0.8,
        reasoning: 'Test operation',
        estimatedTime: DateTime.now(),
        estimatedSize: 1024,
        isApproved: false,
      );
      
      provider.operations.add(operation);
      
      provider.approveOperation('test_op');
      
      expect(operation.isApproved, true);
      expect(operation.isRejected, false);
    });

    test('rejectOperation updates operation rejection status', () {
      // Create a mock operation
      final operation = FileOperation(
        id: 'test_op',
        type: FileOperationType.move,
        sourcePath: '/test/file.txt',
        destinationPath: '/test/dest/file.txt',
        confidence: 0.8,
        reasoning: 'Test operation',
        estimatedTime: DateTime.now(),
        estimatedSize: 1024,
        isApproved: true,
      );
      
      provider.operations.add(operation);
      
      provider.rejectOperation('test_op');
      
      expect(operation.isApproved, false);
      expect(operation.isRejected, true);
    });

    test('approveAllOperations updates all operations', () {
      // Create multiple mock operations
      for (int i = 0; i < 3; i++) {
        provider.operations.add(FileOperation(
          id: 'test_op_$i',
          type: FileOperationType.move,
          sourcePath: '/test/file$i.txt',
          destinationPath: '/test/dest/file$i.txt',
          confidence: 0.8,
          reasoning: 'Test operation $i',
          estimatedTime: DateTime.now(),
          estimatedSize: 1024,
          isApproved: false,
        ));
      }
      
      provider.approveAllOperations();
      
      for (final operation in provider.operations) {
        expect(operation.isApproved, true);
        expect(operation.isRejected, false);
      }
    });

    test('rejectAllOperations updates all operations', () {
      // Create multiple mock operations
      for (int i = 0; i < 3; i++) {
        provider.operations.add(FileOperation(
          id: 'test_op_$i',
          type: FileOperationType.move,
          sourcePath: '/test/file$i.txt',
          destinationPath: '/test/dest/file$i.txt',
          confidence: 0.8,
          reasoning: 'Test operation $i',
          estimatedTime: DateTime.now(),
          estimatedSize: 1024,
          isApproved: true,
        ));
      }
      
      provider.rejectAllOperations();
      
      for (final operation in provider.operations) {
        expect(operation.isApproved, false);
        expect(operation.isRejected, true);
      }
    });

    test('resetState clears all state', () {
      // Set up some state
      provider.setSourcePath('/test/source');
      provider.setDestinationPath('/test/dest');
      provider.setOrganizationStyle(OrganizationStyle.byType);
      provider.setCustomIntent('Test intent');
      
      provider.resetState();
      
      expect(provider.sourcePath, isEmpty);
      expect(provider.destinationPath, isEmpty);
      expect(provider.organizationStyle, OrganizationStyle.smartCategories);
      expect(provider.customIntent, isEmpty);
      expect(provider.operations, isEmpty);
      expect(provider.status, OperationStatus.idle);
    });

    test('canExecute returns true when approved operations exist', () {
      // Create approved and rejected operations
      provider.operations.addAll([
        FileOperation(
          id: 'approved_op',
          type: FileOperationType.move,
          sourcePath: '/test/file1.txt',
          destinationPath: '/test/dest/file1.txt',
          confidence: 0.8,
          reasoning: 'Approved operation',
          estimatedTime: DateTime.now(),
          estimatedSize: 1024,
          isApproved: true,
          isRejected: false,
        ),
        FileOperation(
          id: 'rejected_op',
          type: FileOperationType.move,
          sourcePath: '/test/file2.txt',
          destinationPath: '/test/dest/file2.txt',
          confidence: 0.8,
          reasoning: 'Rejected operation',
          estimatedTime: DateTime.now(),
          estimatedSize: 1024,
          isApproved: false,
          isRejected: true,
        ),
      ]);
      
      expect(provider.canExecute, true);
    });

    test('canExecute returns false when no approved operations exist', () {
      // Create only rejected operations
      provider.operations.add(FileOperation(
        id: 'rejected_op',
        type: FileOperationType.move,
        sourcePath: '/test/file.txt',
        destinationPath: '/test/dest/file.txt',
        confidence: 0.8,
        reasoning: 'Rejected operation',
        estimatedTime: DateTime.now(),
        estimatedSize: 1024,
        isApproved: false,
        isRejected: true,
      ));
      
      expect(provider.canExecute, false);
    });
  });
}
